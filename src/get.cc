#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <string.h>
#include <cgicc/Cgicc.h>
#include <cgicc/HTTPPlainHeader.h>
#include <map>

#include <libs3.h>
#include <libxml/xmlwriter.h>

using namespace std;

struct _mt {
	const char* ext;
	string type;
}
mime_types[]=
{
	{ "", string("application/octet-stream") },
	{ "jpg",  string("image/jpeg") },
	{ "jpeg", string("image/jpeg") },
	{ "gif",  string("image/gif") },
	{ "html",  string("text/html") },
	{ "xml",  string("text/xml") }
};

class Config
{
	map<string,string> m_map;
public:
	Config();
	~Config() {}
	
	const string& get(string s);
	const char* getptr(string s);
};

Config::Config()
{
	string s3key,s3secret;
	ifstream aws("../conf/s3.conf");
	aws >> s3key >> s3secret;
	m_map["S3AccessKey"]=s3key;
	m_map["S3SecretAccessKey"]=s3secret;
}

const string& Config::get(string s)
{
	return m_map[s];
}

const char* Config::getptr(string s)
{
	return m_map[s].c_str();
}

const char* get_filename(const string& key)
{
	const char* p=strrchr(key.c_str(),'/');
	if (p)
	{
		return p+1;
	}
	return key.c_str();
}

const string& get_mime_type(const string& key)
{
	const char* p=strrchr(key.c_str(),'.');
	if (p)
	{
		for (size_t i=1;i<(sizeof(mime_types)/sizeof(mime_types[0]));++i)
		{
			if (!strcasecmp(p+1,mime_types[i].ext))
				return mime_types[i].type;
		}
	}
	return mime_types[0].type;
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
			
			cout << "Content-Disposition: attachment; filename=" << get_filename(key) << endl;
			cgicc::HTTPContentHeader ct=cgicc::HTTPContentHeader(get_mime_type(key));
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