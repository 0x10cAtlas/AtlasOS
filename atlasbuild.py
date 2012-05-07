#!/bin/python

#AtlasOS build script
#Gower


"""Assembles the AtlasOS operating system for DCPU-16.

USAGE:
  python build.py [options]

OPTIONS:
  -d, --disassemble  Produces an additional disassembled file
  -l, --listing      Produces an Organic listing
  -u, --upload       Uploads output to 0x10co.de
  -v, --vfs          Builds the virtual file system before building AtlasOS
  -h, --help         Displays this message
"""


from os.path import join


#N.B. the join function produces the correct paths for the OS the script is
#being run on. E.g. join('some', 'path') returns 'some\path' on windows, but on
#Mac and Linux it returns 'some/path'.

ATLAS = '' #We assume Atlas is in the in the current working directory
MONO = 'mono' #Only applicable for Mac and Linux
PYTHON = 'python'
JAVA = 'java'
VFSBUILDER = join(ATLAS, 'utilities', 'vfsbuilder', 'vfsbuilder.py')
ORGANIC = join(ATLAS, 'Organic.exe')
BIN2ASMBIN = join(ATLAS, 'utilities', 'bin2asmbin', 'bin2asmbin.jar')
KERNEL = join(ATLAS, 'kernel', '')
KERNEL_CORE = join(KERNEL, 'core.dasm16')
OUTPUT_BIN = join(ATLAS, 'AtlasOS.bin')
OUTPUT_LISTING = join(ATLAS, 'Atlas_listing.txt')
OUTPUT_DISASSEMBLE = join(ATLAS, 'AtlasOS_d.dasm16')


def build(disassemble=False, listing=False, upload=False, vfs=False):
	"""Builds AtlasOS, assuming that it's in the current working directory.
	Arguments:
	disassemble -- Whether or not to run bin2asmbin
	listing     -- Whether or not to produce an Organic listing
	upload      -- Whether or not to upload to 0x10co.de
	vfs         -- Whether or not to build the vfs first
	"""
	from subprocess import call
	if vfs:
		v = PYTHON + ' ' + VFSBUILDER
		if len(ATLAS) > 0: v += ' --atlas ' + ATLAS
		call(v, shell=True)
	organic = ""
	from sys import platform
	if not platform.startswith('win'):
		organic  += MONO + " "
	organic += ORGANIC + ' --working-directory ' + KERNEL + ' --input-file ' + KERNEL_CORE + ' --output-file ' + OUTPUT_BIN
	if listing:
		organic += ' --listing ' + OUTPUT_LISTING
	if upload:
		organic += ' --0x10co.de'
	call(organic, shell=True)
	if disassemble:
		call(JAVA + ' -jar ' + BIN2ASMBIN + ' ' + OUTPUT_BIN + ' ' + OUTPUT_DISASSEMBLE + ' -l', shell=True)


def main():
	"""Processes command line arguments and calls build(...) accordingly."""
	from sys import argv
	from getopt import getopt
	opts, args = getopt(argv[1:], 'dluvh', ['disassemble', 'listing', 'upload', 'vfs', 'help'])
	disassemble = False
	listing = False
	upload = False
	vfs = False
	for opt in opts:
		if opt[0] in ('-h', '--help'):
			print __doc__
			return 0
		if opt[0] in ('-d', '--disassemble'):
			disassemble = True
		if opt[0] in ('-l', '--listing'):
			listing = True
		if opt[0] in ('-u', '--upload'):
			upload = True
		if opt[0] in ('-v', '--vfs'):
			vfs = True
	print 'Building AtlasOS...'
	build(disassemble, listing, upload, vfs)
	print 'AtlasOS Built.'
	return 0


if __name__ == "__main__":
	exit(main())

