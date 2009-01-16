#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <string.h>

#include <libs3.h>
#include <libxml/xmlwriter.h>

const char* const APP_ROOT_DIR="/s3";

const xmlChar* BinaryToXMLChar(unsigned int n)
{
	static xmlChar buf[1024];
	sprintf((char*)buf,"%d",n);
	return buf;
}

using namespace std;

string g_accessKeyId;
string g_secretAccessKey;


S3Status my_S3ResponsePropertiesCallback(const S3ResponseProperties *properties, void *callbackData);
void my_S3ResponseCompleteCallback(S3Status status, const S3ErrorDetails *errorDetails, void *callbackData);
S3Status my_S3ListServiceCallback(const char *ownerId, const char *ownerDisplayName, const char *bucketName, int64_t creationDateSeconds, void *callbackData);
S3Status my_S3ListBucketCallback(int isTruncated, const char *nextMarker, int contentsCount, const S3ListBucketContent *contents, int commonPrefixesCount, const char **commonPrefixes, void *callbackData);

struct CallbackData
{
	bool continuing;
	const xmlChar* xmltag;
	xmlTextWriterPtr xmlwriter;
	const char* xslname;
	
	CallbackData() : continuing(false), xmltag(0), xmlwriter(0) {}
};

struct ListBucketsCallbackData : public CallbackData
{
	uint32_t count;
	
	ListBucketsCallbackData() : count(0) {}
};

struct ListBucketCallbackData : public CallbackData
{
	uint32_t count;
	bool complete;
	const char* marker;
	const char* bucketname;
	
	ListBucketCallbackData() : count(0),complete(true),marker(0) {}
};


int main(int argc, char* argv[])
{
	string secretfname=getenv("HOME");
	if (secretfname.length()==0)
	{
		cerr << "Unable to determine HOME" << endl;
		return -2;
	}
	
	secretfname+="/.awssecret";
	ifstream awssecrets(secretfname.c_str());
	awssecrets >> g_accessKeyId >> g_secretAccessKey;
	if (!awssecrets.good())
	{
		cerr << "Unable to read S3 key and secret key from ~/.awssecret" << endl;
		return -1;
	}
	
	if (S3_initialize("TroyS3",S3_INIT_ALL)!=S3StatusOK)
	{
	}
	else
	{	
		S3ResponseHandler handler;
		handler.propertiesCallback=my_S3ResponsePropertiesCallback;
		handler.completeCallback=my_S3ResponseCompleteCallback;
	
		if (argc<2)
		{
			S3ListServiceHandler callback;
			callback.responseHandler=handler;
			callback.listServiceCallback=my_S3ListServiceCallback;
	
			ListBucketsCallbackData data;
			data.xmltag=BAD_CAST "bucket_list";
			data.xslname="buckets.xsl";

			// Create XMLWriter
			data.xmlwriter=xmlNewTextWriterFilename("/dev/stdout",0);
			if (!data.xmlwriter)
				std::cerr << "xmlNewTextWriterFilename failed" << std::endl;
		
			S3_list_service(S3ProtocolHTTPS,g_accessKeyId.c_str(),g_secretAccessKey.c_str(),NULL,&callback,&data);
		}
		else
		{
			S3BucketContext context;
	
			context.bucketName=argv[1];
			context.protocol=S3ProtocolHTTPS;
			context.uriStyle=S3UriStylePath;
			context.accessKeyId=g_accessKeyId.c_str();
			context.secretAccessKey=g_secretAccessKey.c_str();
		
			S3ListBucketHandler bhandler;
			bhandler.responseHandler=handler;
			bhandler.listBucketCallback=my_S3ListBucketCallback;
		
			ListBucketCallbackData data;
			data.xmltag=BAD_CAST "contents";
			data.bucketname=context.bucketName;
			data.xslname="bucket.xsl";

			// Create XMLWriter
			data.xmlwriter=xmlNewTextWriterFilename("/dev/stdout",0);
			if (!data.xmlwriter)
				std::cerr << "xmlNewTextWriterFilename failed" << std::endl;
		
			do
			{
				S3_list_bucket(&context,NULL,data.marker,NULL,0,NULL,&bhandler,&data);
			}
			while (!data.complete);
		}
		
		S3_deinitialize();
	}
	
	return 0;
}

S3Status my_S3ResponsePropertiesCallback(const S3ResponseProperties *properties, void *callbackData)
{
	CallbackData* data=(CallbackData*)callbackData;
	if (data->continuing==false)
	{
		xmlTextWriterStartDocument(data->xmlwriter,NULL,NULL,NULL);
		xmlTextWriterWriteFormatPI(data->xmlwriter,BAD_CAST "xml-stylesheet","type=\"text/xsl\" href=\"%s/xsl/%s\"",APP_ROOT_DIR,data->xslname);
		xmlTextWriterStartElement(data->xmlwriter,BAD_CAST "response");
		xmlTextWriterStartElement(data->xmlwriter,BAD_CAST "properties");
		xmlTextWriterWriteElement(data->xmlwriter,BAD_CAST "requestId",BAD_CAST properties->requestId);
		xmlTextWriterWriteElement(data->xmlwriter,BAD_CAST "requestId2",BAD_CAST properties->requestId2);
		
		if (properties->server)
			xmlTextWriterWriteElement(data->xmlwriter,BAD_CAST "server",BAD_CAST properties->server);
		
		if (properties->eTag)
		{
			xmlTextWriterWriteElement(data->xmlwriter,BAD_CAST "eTag",BAD_CAST properties->eTag);
		}
		
		if (properties->lastModified>=0)
		{
			xmlTextWriterStartElement(data->xmlwriter,BAD_CAST "lastModified");
			xmlTextWriterWriteAttribute(data->xmlwriter,BAD_CAST "value",BinaryToXMLChar(properties->lastModified));
			xmlTextWriterEndElement(data->xmlwriter);
		}
		
		const S3NameValue* dp=properties->metaData;
		for (int i=0;i<properties->metaDataCount;++i)
		{
			xmlTextWriterStartElement(data->xmlwriter,BAD_CAST "metadata");
			xmlTextWriterWriteAttribute(data->xmlwriter,BAD_CAST "name",BAD_CAST dp->name);
			xmlTextWriterWriteCDATA(data->xmlwriter,BAD_CAST dp->value);
			xmlTextWriterEndElement(data->xmlwriter);

			dp++;
		}
		
		xmlTextWriterEndElement(data->xmlwriter);
	}
	
	return S3StatusOK;
}

void my_S3ResponseCompleteCallback(S3Status status, const S3ErrorDetails *errorDetails, void *callbackData)
{
	switch (status)
	{
		case S3StatusOK:
		{
			CallbackData* data=(CallbackData*)callbackData;
			if (data)
			{
				if (data->continuing==false)
				{
					if (data->xmlwriter)
						xmlTextWriterEndDocument(data->xmlwriter);
				}
			}
			break;
		}
		default:
			cerr << "Error:" << S3_get_status_name(status) << endl;
			break;
	}

}

S3Status my_S3ListServiceCallback(const char *ownerId, const char *ownerDisplayName, const char *bucketName, int64_t creationDateSeconds, void *callbackData)
{
	ListBucketsCallbackData* data=(ListBucketsCallbackData*)callbackData;
	if (data && data->count==0 && data->xmltag)
	{
		xmlTextWriterStartElement(data->xmlwriter,data->xmltag);
	}

	xmlTextWriterStartElement(data->xmlwriter,BAD_CAST "bucket");
		xmlTextWriterWriteElement(data->xmlwriter,BAD_CAST "creationdate", BinaryToXMLChar(creationDateSeconds));
	
		xmlTextWriterStartElement(data->xmlwriter,BAD_CAST "owner");
			xmlTextWriterWriteElement(data->xmlwriter,BAD_CAST "id", BAD_CAST ownerId);

			xmlTextWriterWriteElement(data->xmlwriter,BAD_CAST "displayname", BAD_CAST ownerDisplayName);
		xmlTextWriterEndElement(data->xmlwriter);

		xmlTextWriterWriteElement(data->xmlwriter,BAD_CAST "name", BAD_CAST bucketName);
	xmlTextWriterEndElement(data->xmlwriter);
	
	data->count++;
	
	return S3StatusOK;
}

S3Status my_S3ListBucketCallback(int isTruncated, const char *nextMarker, int contentsCount, const S3ListBucketContent *contents, int commonPrefixesCount, const char **commonPrefixes, void *callbackData)
{
	
	ListBucketCallbackData* data=(ListBucketCallbackData*)callbackData;
	if (data)
	{
		data->complete=false;
		
		if (data->count==0)
		{
			xmlTextWriterStartElement(data->xmlwriter,BAD_CAST "meta");
		
			if (data->bucketname)
				xmlTextWriterWriteElement(data->xmlwriter,BAD_CAST "docname",BAD_CAST data->bucketname);
			
			char datetime[32];
			time_t now=time(0);
			struct tm tm;
			localtime_r(&now,&tm);
			sprintf(datetime,"%04d-%02d-%02dT%02d:%02d:%02d",tm.tm_year+1900,tm.tm_mon+1,tm.tm_mday,tm.tm_hour,tm.tm_min,tm.tm_sec);
			xmlTextWriterWriteElement(data->xmlwriter,BAD_CAST "doctime",BAD_CAST datetime);
		
			xmlTextWriterEndElement(data->xmlwriter);
		
			if (data->xmltag)
				xmlTextWriterStartElement(data->xmlwriter,data->xmltag);
		}
		
		data->count++;
	}
	
		
	const S3ListBucketContent* bc=contents;
	
	const char* lastkey;
	for (int i=0;i<contentsCount;++i)
	{
		xmlTextWriterStartElement(data->xmlwriter,BAD_CAST "key");
		
		struct tm tm;
		localtime_r((time_t*)&bc->lastModified,&tm);
		xmlTextWriterWriteFormatAttribute(data->xmlwriter,BAD_CAST "lastmodified","%04d-%02d-%02dT%02d:%02d:%02d",tm.tm_year+1900,tm.tm_mon+1,tm.tm_mday,tm.tm_hour,tm.tm_min,tm.tm_sec);
		
		// Trim quotes from beginning and end
		char etag[128];
		const char* p;
		for (p=bc->eTag;*p=='"';++p);
		strncpy(etag,p,sizeof(etag));
		etag[sizeof(etag)-1]='\0';
		for (char* p=&etag[min(sizeof(etag),strlen(etag))-1];*p=='"';--p)
			*p='\0';
		
		xmlTextWriterWriteAttribute(data->xmlwriter,BAD_CAST "eTag",BAD_CAST etag);
		xmlTextWriterWriteAttribute(data->xmlwriter,BAD_CAST "size",BAD_CAST BinaryToXMLChar(bc->size));
		if (bc->ownerId && bc->ownerDisplayName)
		{
			xmlTextWriterStartElement(data->xmlwriter,BAD_CAST "owner");
			xmlTextWriterWriteAttribute(data->xmlwriter,BAD_CAST "id", BAD_CAST bc->ownerId);
			xmlTextWriterWriteElement(data->xmlwriter,BAD_CAST "name", BAD_CAST bc->ownerDisplayName);
			xmlTextWriterEndElement(data->xmlwriter);
		}
		
		xmlTextWriterWriteElement(data->xmlwriter,BAD_CAST "name", BAD_CAST bc->key);
		xmlTextWriterEndElement(data->xmlwriter);
		
		lastkey=bc->key;
		
		bc++;
	}
	
	if (isTruncated)
	{
		data->marker=lastkey;
		data->continuing=true;
		data->complete=false;
	}
	else
	{
		data->marker=lastkey;
		data->continuing=false;
		data->complete=true;
	}
	
	return S3StatusOK;
}
