#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#define _GNU_SOURCE
#include <getopt.h>
#include <wait.h>
#include <fstream.h>

#include <apt-pkg/configuration.h>
#include <apt-pkg/init.h>
#include <apt-pkg/progress.h>
#include <apt-pkg/pkgcache.h>
#include <apt-pkg/sourcelist.h>
#include <apt-pkg/pkgcachegen.h>
#include <apt-pkg/version.h>

#include "debfile.h"
	
#define TMPDIR "/var/lib/debconf/"
//#define TMPDIR "tmp/"

void help(void)
{
	fprintf(stderr, "apt-extracttemplates deb [deb]\n");
	exit(0);
}

char *writefile(const char *prefix, const char *data)
{
	char fn[512];
	static int i;
	snprintf(fn, sizeof(fn), "%s%s.%u%d", TMPDIR, prefix, getpid(), i++);

	ofstream ofs(fn);
	if (!ofs) return NULL;
	ofs << data;
	ofs.close();
	return strdup(fn);
}

void writeconfig(const DebFile &file)
{
	char *templatefile = writefile("template", file.Template);
	char *configscript = writefile("config", file.Config);

	if (templatefile == 0 || configscript == 0)
	{
		fprintf(stderr, "Cannot write config script or templates\n");
		return;
	}
	printf("%s %s %s %s\n",
		file.Package.c_str(),	// Package
		file.Version.c_str(),	// Version
		templatefile,	// Template
		configscript 	// Config
	);
}

const char *getdebconfver(void)
{
	const char *ver = NULL;
	// Initialize the apt cache, just to get the debconf version...
	if (pkgInitialize(*_config) == false)
	{
		fprintf(stderr, "Cannot initialize apt cache\n");
		return NULL;
	}
	pkgSourceList List;
	List.ReadMainList();
	OpProgress Prog;	
	MMap *Map = pkgMakeStatusCacheMem(List,Prog);
	pkgCache Cache(*Map);
	pkgCache::PkgIterator Pkg = Cache.FindPkg("debconf");
	if (Pkg.end() == false) 
	{
		pkgCache::VerIterator V = Pkg.CurrentVer();
		if (V.end() == false) 
		{
			ver = strdup(V.VerStr());
		}
		else
			fprintf(stderr, "no version\n");

	}
	else
	{
		fprintf(stderr, "no package\n");
	}

	delete Map;

	return ver;
}

int main(int argc, char **argv, char **env)
{
	int idx = 0;
	char **debs = 0;
	int numdebs = 0;
	const char *debconfver = getdebconfver();
	
	if (debconfver == NULL) 
	{
		fprintf(stderr, "Cannot get debconf version. Is debconf installed?\n");
		return 1;
	}

	numdebs = argc - 1;
	debs = new char *[numdebs];
	memcpy(debs, &argv[1], sizeof(char *) * numdebs);

	if (numdebs < 1) return 0;

	for (idx = 0; idx < numdebs; idx++)
	{
		DebFile file(debs[idx]);
		if (file.Go() == false) 
		{
			fprintf(stderr, "Cannot read %s\n", debs[idx]);
			continue;
		}
		if (file.Template != 0 && file.ParseInfo() == true)
		{
			if (file.DepVer != "" &&
			    pkgCheckDep(file.DepVer.c_str(), 
			                debconfver, file.DepOp) == false) 
				continue;
			if (file.PreDepVer != "" &&
			    pkgCheckDep(file.PreDepVer.c_str(), 
			                debconfver, file.PreDepOp) == false) 
				continue;

			writeconfig(file);
		}
	}
	

	return 0;
}
