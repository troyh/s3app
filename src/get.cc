#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <string.h>
#include <cgicc/Cgicc.h>
#include <cgicc/HTTPPlainHeader.h>
#include <map>

#include <libs3.h>
#include <libxml/xmlwriter.h>

#include "Config.h"

using namespace std;

struct MIME_TYPE {
	const char* ext;
	string type;
	bool send_content_disposition;
}
mime_types[]=
{
	{ "", string("application/octet-stream"), true },
	{ "jpg",  string("image/jpeg"), false },
	{ "jpeg", string("image/jpeg"), false },
	{ "gif",  string("image/gif"), false },
	{ "html",  string("text/html"), false },
	{ "xml",  string("text/xml"), false }
};

const char* get_filename(const string& key)
{
	const char* p=strrchr(key.c_str(),'/');
	if (p)
	{
		return p+1;
	}
	return key.c_str();
}

const MIME_TYPE* get_mime_type(const string& key)
{
	const char* p=strrchr(key.c_str(),'.');
	if (p)
	{
		for (size_t i=1;i<(sizeof(mime_types)/sizeof(mime_types[0]));++i)
		{
			if (!strcasecmp(p+1,mime_types[i].ext))
				return &mime_types[i];
		}
	}
	return &mime_types[0];
}

S3Status my_S3ResponsePropertiesCallback(const S3ResponseProperties *properties, void *callbackData)
{
	// cout << "my_S3ResponsePropertiesCallback" << endl;
	const S3NameValue* dp=properties->metaData;
	for (int i=0;i<properties->metaDataCount;++i)
	{
		cout << dp->name << ':' << dp->value << endl;
	
		dp++;
	}
	return S3StatusOK;
}

void my_S3ResponseCompleteCallback(S3Status status, const S3ErrorDetails *errorDetails, void *callbackData)
{
	// cout << "my_S3ResponseCompleteCallback(" << S3_get_status_name(status) << ")" << endl;
}

S3Status my_S3GetObjectDataCallback(int bufferSize, const char *buffer, void *callbackData) 
{
	cout.write(buffer,bufferSize);
	return S3StatusOK;
}

int main()
{
	try
	{
		Config config;
		
		cgicc::Cgicc cgi;
		const cgicc::CgiEnvironment& env=cgi.getEnvironment();
		
		string qs=env.getQueryString();
		
		string key=cgi("key");
		string bucket=cgi("bucket");
		
		if (S3_initialize("TroyS3",S3_INIT_ALL)!=S3StatusOK)
		{
		}
		else
		{
			S3BucketContext context;
			context.bucketName=bucket.c_str();
			context.protocol=S3ProtocolHTTPS;
			context.uriStyle=S3UriStylePath;
			context.accessKeyId=config.getptr("S3AccessKey");
			context.secretAccessKey=config.getptr("S3SecretAccessKey");
			
			S3ResponseHandler rhandler;
			rhandler.propertiesCallback=my_S3ResponsePropertiesCallback;
			rhandler.completeCallback=my_S3ResponseCompleteCallback;
			
			S3GetObjectHandler handler;
			handler.responseHandler=rhandler;
			handler.getObjectDataCallback=my_S3GetObjectDataCallback;
			
			const MIME_TYPE* mt=get_mime_type(key);
			if (mt->send_content_disposition)
				cout << "Content-Disposition: attachment; filename=" << get_filename(key) << endl;
			cgicc::HTTPContentHeader ct=cgicc::HTTPContentHeader(mt->type);
			ct.render(cout);
			
			S3_get_object(&context,key.c_str(),NULL,0,0,NULL,&handler,0);
			
			S3_deinitialize();
		}
		
	}
	catch (exception& x)
	{
		
	}
	
	return 0;
}