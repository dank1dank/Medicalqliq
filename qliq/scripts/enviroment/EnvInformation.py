#! /usr/bin/python

import sys, getopt, os
import plistlib
import commands
import re

def printUsage():
    print '''EnvInformation.py [mode] path
    modes: -w --write,
           -r --revert
    path is path to Info.plist''' 

def main(argv):
    shouldWrite = False
    shouldRevert = False
    path = sys.argv[len(sys.argv)-1]
    try:
        opts, args = getopt.getopt(argv, "-rwh:",["write","revert","help"])
    except getopt.GetoptError:
        printUsage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            printUsage();
            sys.exit()
        elif opt in ("-w", "--write"):
            shouldWrite = True;
        elif opt in ("-r", "--revert"):
            shouldRevert = True
    if os.path.isfile(path) == False:
        print "File",path,"is incorrect"
        printUsage()
        sys.exit(2)
    if shouldWrite:
        write(path)
    elif shouldRevert:
        revert(path)
    else:
        print "Mode is not selected"
        printUsage()
        sys.exit(2)

def isGitAvailable():
    # Check for git
    return True
    
def getGitInfo():
    git_info = dict()
    git_info["type"] = "git"
    git_info["branch"] = commands.getstatusoutput('git rev-parse --abbrev-ref HEAD')[1]
    git_info["commit_number"] = commands.getstatusoutput('git log --oneline | wc -l | tr -d " "')[1]
    git_info["hash_short"] = commands.getstatusoutput('git rev-parse --short HEAD')[1]
    git_info["hash"] = commands.getstatusoutput('git rev-parse HEAD')[1]
    return git_info

def getSourceControlInfo():
    if isGitAvailable():
        return getGitInfo()
    else:
        return "Source control info unavailable"

def getBuildInviroment():
    env_info = dict()
    env_info["clang"] = commands.getstatusoutput('clang -v 2>&1 | head -n 1')[1]
    env_info["llvm"] = commands.getstatusoutput('llvm-gcc --version | head -n 1')[1]
    xcode_version = commands.getstatusoutput('xcodebuild -version')[1]
    env_info["xcode"] = re.sub('\s+',' ',xcode_version)
    return env_info

SourceControlKey = "SourceControl"
EnviromentKey = "BuildEnviroment"

def write(filePath):
    plist = plistlib.readPlist(filePath)
    plist[SourceControlKey] = getSourceControlInfo()
    plist[EnviromentKey] = getBuildInviroment()
    plistlib.writePlist(plist, filePath)
    
def revert(filePath):
    plist = plistlib.readPlist(filePath)
    del plist[SourceControlKey]
    del plist[EnviromentKey] 
    plistlib.writePlist(plist, filePath)

if __name__ == "__main__":
   main(sys.argv[1:])
