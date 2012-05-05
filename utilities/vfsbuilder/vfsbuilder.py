#!/bin/python

"""
	AtlasOS VFS Builder 
	Gower
	
	Version: Murky
	
	Use at own risk, absolutely no warranty provided.
	
	As a standalone script, can take a directory and convert all of its contents,
	including subdirectories, into the virtual file system (VFS) for AtlasOS. As
	a library, it provides classes and methods to allow scripts to easily create
	an AtlasOS VFS.
"""


import os
from binascii import hexlify as byte_to_hex


class Table:
	"""
		This processes and creates the VFS table. Start by adding the root
		directory, then files and more directories.
		
		When you add a directory, you get the ID of that directory so you can
		add more stuff to it. You must give a directory ID when adding a
		directory or file. The root directory ID is 0.
	"""
	
	def __init__(self):
		self.directoryEntries = []
		self.fileEntries = []
	
	def addRootDirectory(self):
		"""Automatically creates the root directory for you."""
		return self.addDirectory(0, '/')
	
	def addDirectory(self, dir_id, name, flags=None):
		"""Adds a new directory (both to the table and the VFS). Flags must be 
		   omitted, in which case the default is read/dir, or a Flags
		   object. Returns the ID for the newly created directory"""
		id = len(self.directoryEntries)
		self.directoryEntries.append(DirectoryEntry(dir_id, name, id, flags))
		return id
	
	def addFile(self, dir_id, name, label=None, flags=None):
		"""Adds a new file to the table (not to the VFS). Label can be anything
		   but should be unique to that file. If omitted, it's a number. Flags
		   must be omitted, in which case the default is read/write, or a Flags
		   object. Returns the FileLabels object for the newly entered file"""
		n_entries = len(self.fileEntries)
		if label == None: label = "file"+str(n_entries)
		self.fileEntries.append(FileEntry(dir_id, name, label, flags))
		return self.fileEntries[n_entries].labels
	
	def writeToFile(self, outf):
		outf.write(":files_table\n\tdat 0x{0:x}\n".format(len(self.directoryEntries) + len(self.fileEntries)))
		for entry in (self.directoryEntries + self.fileEntries):
			outf.write(str(entry))
		outf.write(":files_table_end\n\n")


class Entry:
	"""
		Generic class for an entry to the VFS table. Processes any file name
		into one that is acceptable for the VFS.
	"""
	
	maxNameLength = 15
	
	def __init__(self, dir_id, flags, name, labels):
		self.dir_id = dir_id
		self.flags = flags
		self.processName(name)
		self.labels = labels
	
	def processName(self, name):
		name = name[:Entry.maxNameLength].replace(" ", "_") #Limit name length to max and replace spaces
		spaces = Entry.maxNameLength - len(name) #Number of spaces to add to padding
		self.name = "\"{0}\", 0{1}".format(name, ", \"{0}\"".format(" "*spaces))
	
	def __str__(self):
		return "\tdat 0x{0:x}, {1}, {2}, {3}, {4}\n".format(self.dir_id, self.flags, self.name, self.labels.start, self.labels.end)


class DirectoryEntry(Entry):
	
	"""
		A directory entry to the VFS table. Takes the ID of the directory and makes
		labels out of it.
	"""
	
	def __init__(self, dir_id, name, id, flags=None):
		if flags == None: flags = Flags(True, False, False, False, True)
		Entry.__init__(self, dir_id, flags, name, DirectoryLabels(id))


class FileEntry(Entry):
	
	"""
		A file entry to the VFS (not a VFS file).
	"""
	
	def __init__(self, dir_id, name, label, flags=None):
		if flags == None: flags = Flags(True, True, False, False, False)
		Entry.__init__(self, dir_id, flags, name, FileLabels(label))


class Labels:
	
	"""
		Generic labels class for the VFS table.
	"""
	
	def __init__(self, start, end):
		self.start = start
		self.end = end


class FileLabels(Labels):
	
	"""
		Takes some label for a file and creates a corresponding end label.
	"""
	
	def __init__(self, start):
		Labels.__init__(self, start, start + "_end")


class DirectoryLabels(Labels):
	
	"""
		Creates the special labels for directory entries. The 'end' is actually
		just 0, and the 'start' is the ID of the directory.
	"""
	
	def __init__(self, id):
		Labels.__init__(self, "0x{0:x}".format(id), "0x0")


class Flags:
	
	"""
		Creates a flag for the VFS table. E.g.
			Flags(True, True, True, False, False)
		Creates a flag which indicates readability, writeability, and hidiness.
	"""
	
	READ =   0b00001 #File is readable
	WRITE =  0b00010 #File is writable
	HIDDEN = 0b00100 #File is hidden
	EXE =    0b01000 #File is executable
	DIR =    0b10000 #File is a directory
	
	def __init__(self, read, write, hidden, executable, directory):
		self.flag = 0
		if read: self.flag |= Flags.READ
		if write: self.flag |= Flags.WRITE
		if hidden: self.flag |= Flags.HIDDEN
		if executable: self.flag |= Flags.EXE
		if directory: self.flag |= Flags.DIR
	
	def __int__(self):
		return self.flag
	
	def __str__(self):
		return "0x{0:x}".format(self.flag)
	
	def getFlagsFromFileName(name):
		if name[0] != '--': #If there's no flag, uh, flag, then just return the default
			return name, Flags(True, True, False, False, False)
		#Since there's a flag-flag, we want to find where the flags end, which is the first '.'
		dot_pos = name.find('.')
		if dot_pos == -1: #Clearly if there isn't a dot, we've made a mistake, so skip over
			return name, Flags(True, True, False, False, False)
		flag_str = name[2:dot_pos].lower()
		#Now it's time for the flag-flag flags. Or something
		r = w = h = e = d = False
		if 'r' in flag_str: r = True
		if 'w' in flag_str: w = True
		if 'h' in flag_str: h = True
		if 'e' in flag_str: e = True
		if 'd' in flag_str: d = True
		return name[dot_pos+1:], Flags(r, w, h, e, d)


class File:
	
	"""
		A file in the VFS.
	"""
	
	def __init__(self, labels, real_path):
		self.labels = labels
		self.real_path = real_path
	
	def writeToFile(self, outf):
		#We want to end up with lines of no more than 8 words, where each word
		#is in the form 0x1234, separated by commas. Each line is separated by
		#a new line and a tab, and started by a dat code.
		inf = open(self.real_path, 'rb')
		outf.write(self.labels.start + ":\n\tdat ")
		word_count = 0 #How many words are on the current line
		word = inf.read(2) #Read 16 bits at a time
		while word:
			word = byte_to_hex(word) #Convert each word to hex
			l = len(word) 
			if l < 4: #Is each word 4 characters long?
				word += "0" * (4-l) #If not, pad it out with 0s
			outf.write("0x"+word)
			word_count += 1 #There's one more word on the line
			
			word = inf.read(2) #Read 16 more bits
			if word: #If we read anything from the file
				if word_count >= 8: #If it's the end of the line, write a new line
					outf.write("\n\tdat ")
					word_count = 0
				else: #Else it's the middle of a line
					outf.write(", ")
		inf.close()
		outf.write("\n"+self.labels.end + ":\n\n")
			

class FileList(list):
	
	"""
		The list of files in the VFS.
	"""
	
	def __init__(self):
		list.__init__(self)
	
	def addFile(self, labels, real_path):
		self.append(File(labels, real_path))
	
	def writeToFile(self, outf):
		for item in self:
			item.writeToFile(outf)


class VirtualFileSystem:
	
	"""
		An AtlasOS VFS.
	"""
	
	def __init__(self):
		self.table = Table()
		self.fileList = FileList()
	
	def addDirectory(self, dir_id, name, flags=None):
		return self.table.addDirectory(dir_id, name, flags)
	
	def addRootDirectory(self):
		return self.table.addRootDirectory()
	
	def addFile(self, real_path, dir_id, name, flags=None, label=None):
		labels = self.table.addFile(dir_id, name, label, flags)
		self.fileList.addFile(labels, real_path)
	
	def writeToFile(self, outf):
		outf.write(":files\n\n")
		self.table.writeToFile(outf)
		self.fileList.writeToFile(outf)
		outf.write(":files_end\n")
	
	def addFromRealDirectory(self, directory, dir_id):
		items = os.listdir(directory)
		for item in items:
			if item[0] == '.': #Skip dotted files
				continue
			full_path = os.path.join(directory, item)
			if os.path.isdir(full_path):
				id = self.addDirectory(dir_id, item)
				self.addFromRealDirectory(full_path, id)
			else:
				flagless_name, flags = Flags.getFlagsFromFileName(full_path)
				self.addFile(full_path, dir_id, flagless_name, flags)


def process_args():
	from sys import argv
	from getopt import getopt
	optlist, args = getopt(argv[1:], "a:r:", ['atlas=', 'root='])
	atlas = None
	root = None
	for opt in optlist:
		if opt[0] in ('-a', '--atlas'):
			atlas = opt[1]
		if opt[0] in ('-r', '--root'):
			root = opt[1]
	if atlas == None:
		atlas = os.getcwd()
	if root == None:
		root = os.path.join(atlas, 'misc', 'vfs')
	vfs_file = os.path.join(atlas, 'misc', 'vfs.dasm16')
	return root, vfs_file


def main():
	print 'AtlasOS Virtual File System Builder'
	paths = process_args()
	for path in paths:
		if not os.access(path, os.F_OK):
			print 'Path "'+path+'" does not exist. Could not continue.'
			return 1
	root, vfs_file = paths
	vfs = VirtualFileSystem()
	root_id = vfs.addRootDirectory()
	print 'Collecting real files and directories...'
	vfs.addFromRealDirectory(root, root_id)
	print 'Writing to VFS file...'
	outf = open(vfs_file, 'w')
	vfs.writeToFile(outf)
	print 'Done.'
	return 0


if __name__ == "__main__":
	exit(main())

