#ifndef _debfile_H
#define _debfile_H

#include <string>
#include <apt-pkg/fileutl.h>
#include <dirstream.h>

class DebFile : public pkgDirStream
{
	const char *ParseDepends(const char *Start,const char *Stop,
				string &Package,string &Ver,
				unsigned int &Op);

	FileFd File;
	unsigned long Size;
	char *Control;
	unsigned long ControlLen;
	
public:
	DebFile(string FileName);
	~DebFile();
	bool DoItem(Item &I, int &fd);
	bool Process(pkgDirStream::Item &I, const unsigned char *data, 
		unsigned long size, unsigned long pos);

	bool Go();
	bool ParseInfo();

	string Package;
	string Version;
	string DepVer, PreDepVer;
	unsigned int DepOp, PreDepOp;

	char *Config;
	char *Template;
	enum { None, IsControl, IsConfig, IsTemplate } Which;
};

#endif
