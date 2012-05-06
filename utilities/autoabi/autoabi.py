#!/bin/python


import os, re


class AssemblyRelocationTable(list):
			
	def __init__(self):
		list.__init__(self)
	
	def addEntries(self, list):
		self.extend(list)
	
	def addEntry(self, label):
		self.append(label)
	
	def calculateLength(self):
		return len(self) + 1 #+1 for the word which is the length of the table
	
	def __str__(self):
		out = "dat 0x{0:x}".format(len(self))
		for label in self:
			out += ", " + label
		return out


class ABIHeader:
	
	def __init__(self, code_length, flags, art=None):
		self.magic_number = 0x4714
		self.version = 0x0001
		self.code_length = code_length
		self.flags = flags
		self.art = art
	
	def calculateLength(self):
		self.length = 0x5 #The header is at least 5 words long
		if self.art != None: self.length += self.art.calculateLength()
	
	def __str__(self):
		self.calculateLength()
		out = ";START HEADER\n\ndat 0x{0:x}, 0x{1:x}, 0x{2:x}, 0x{3:x}, 0x{4:x}\n\n".format(self.magic_number, self.version, self.length, self.code_length, int(self.flags))
		if self.art != None:
			out += ";Assembly Relocation Table\n{5}\n\n".format(str(self.art))
		return out + ";END HEADER"


class Flags:
	
	HAS_ART =    0b00001
	REALTIME =   0b00010
	BACKGROUND = 0b00100
	DRIVER =     0b01000
	LIBRARY =    0b10000
	
	def __init__(self, has_art, realtime, background, driver, library):
		self.has_art = has_art
		self.realtime = realtime
		self.background = background
		self.driver = driver
		self.library = library
	
	def __int__(self):
		f = 0
		if self.has_art: f |= Flags.HAS_ART
		if self.realtime: f |= Flags.REALTIME
		if self.background: f |= Flags.BACKGROUND
		if self.driver: f |= Flags.DRIVER
		if self.library: f |= Flags.LIBRARY
		return f


def process_args():
	from sys import argv
	from getopt import getopt
	optlist, args = getopt(argv[1:], "arbdl", ['source=', 'binary='])
	source = binary = None
	a = r = b = d = l = False
	for opt in optlist:
		if opt[0] == '--source': source = opt[1]
		if opt[0] == '--binary': binary = opt[1]
		if opt[0] == '-a': a = True
		if opt[0] == '-r': r = True
		if opt[0] == '-b': b = True
		if opt[0] == '-d': d = True
		if opt[0] == '-l':
			l = True
			print 'Notice: autoabi does not currently support libraries.'
	return source, binary, Flags(a, r, b, d, l)


def main():
	src, bin, flags = process_args()
	code_length = os.path.getsize(bin)
	art = None
	if flags.has_art:
		art = AssemblyRelocationTable()
		f = open(src, 'r')
		source = f.read()
		f.close()
		labels = re.match("\s[A-Za-z0-9]:", source).groups()
		art.addEntries(labels)
	abi = ABIHeader(code_length, flags, art)
	print abi
	return 0


if __name__ == '__main__':
	exit(main())


