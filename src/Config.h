#include <string>
#include <map>

using namespace std;

class Config
{
	map<string,string> m_map;
public:
	Config();
	~Config() {}
	
	const string& get(string s);
	const char* getptr(string s);
};
