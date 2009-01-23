#include <fstream>

#include "Config.h"

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

