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

S3Status my_S3ResponsePropertiesCallback(const S3ResponseProperties *properties, void *callbackData)
{
	return S3StatusOK;
}

void my_S3ResponseCompleteCallback(S3Status status, const S3ErrorDetails *errorDetails, void *callbackData)
{
	cgicc::HTTPContentHeader ct=cgicc::HTTPContentHeader("text/xml");
	ct.render(cout);

	if (status==S3StatusOK)
	{
		cout << "<ok/>" << endl;
	}
	else
	{
		cout << "<error/>" << endl;
	}
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

			string bucket_name=cgi("name");
			
			// TODO: Validate name (require AccessKey prefix?)
			
			S3ResponseHandler create_bucket_handler;
			create_bucket_handler.propertiesCallback=my_S3ResponsePropertiesCallback;
			create_bucket_handler.completeCallback=my_S3ResponseCompleteCallback;
			
			S3_create_bucket(S3ProtocolHTTPS,config.get("S3AccessKey").c_str(),config.get("S3SecretAccessKey").c_str(),bucket_name.c_str(),S3CannedAclPrivate,NULL,NULL,&create_bucket_handler,0);
			
			S3_deinitialize();
		}
		
	}
	catch (exception& x)
	{
		
	}
	
	return 0;
}
