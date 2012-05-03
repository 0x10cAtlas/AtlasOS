#!/bin/python

#AtlasOS Virtual File System builder
#Gower
#
#Takes files found in misc/vfs and converts them into Atlas's virtual file system
#
#Official release status: Rough around the edges. Use at own risk, absolutely no warranty, etc.
#Probably will never be cleaned up since the VFS is a temporary thing


import os, binascii


#Flags      DEHWR
Fread =   0b00001
Fwrite =  0b00010
Fhidden = 0b00100
Fexe =    0b01000
Fdir =    0b10000
Fdirectory = Fread | Fdir #Since we're going to want to read directories
Freadexe = Fread | Fexe #Executables need to be readable too, but probably not writable
Freadwrite = Fread | Fwrite #Normal data files need to be both of these


#Keep track of things
directories = {}
files = []
entries = []
max_name_len = 15 #plus 1 for 0-termination


def make_vfs():
	return ":files\n\n{0}\n\n{1}:files_end\n".format(make_table(), make_files())


def make_table():
	e = ""
	for entry in entries:
		e += entry
	return ":files_table\n\tdat 0x{0:x}\n{1}:files_table_end".format((len(directories) + len(files)), e)


def make_table_entry(item):
	entries.append("\tdat 0x{0:x}, 0x{1:x}, {2}, {3}, {4}\n".format(item['directory'], item['flags'], item['name'], item['labels']['start'], item['labels']['end']))


def make_dir(directory, name):
	l = len(directories) #This will be the ID of the directory
	directories[os.path.join(directory, name)] = l
	make_table_entry({
		'directory': directories[directory],
		'flags': Fdirectory,
		'name': make_name(name),
		'labels': {'start': "0x{0:x}".format(l), 'end': "0x0"}
	})


def make_file(directory, flags, name, data):
	l = len(files) #This will be the ID of the file
	content = make_content(data)
	f = {
		'directory': directories[directory],
		'flags': flags,
		'name': make_name(name),
		'labels': make_labels(l),
		'content': content
	}
	files.append(f)
	make_table_entry(f)


def make_name(name):
	name = name[:max_name_len].replace(" ", "_") #Limit name length to max and replace spaces
	spaces = max_name_len - len(name) #Number of spaces to add to padding
	return "\"{0}\", 0{1}".format(name, ", \"{0}\"".format(" "*spaces))


def make_labels(l):
	label = 'file'+str(l)
	return {
		'start': label,
		'end': label+'_end'
	}


def make_files():
	f = ""
	for fle in files:
		a = fle['labels']['start']
		b = fle['content']
		c = fle['labels']['end']
		f += "{0}:\n{1}{2}:\n\n".format(a, b, c)
	return f


def make_content(data):
	data = binascii.hexlify(data)
	content = "\tdat "
	#Going to split the data (which is in text hex) into groups of 32 characters, and then into groups of 4 characters
	#Each line will have a dat with 8 words
	n_lines = (len(data)/32) + 1
	num_of_eights = (len(data)/(8*4))+1
	i = 0
	while i < n_lines:
		n = 0
		line = data[i*32:(i+1)*32]
		n_words = (len(line)/4)
		while n < n_words:
			word = line[n*4:(n*4)+4]
			content += "0x" + word
			chars = len(word)
			if chars < 4:
				#This means we don't have a whole 16-bits of data at the end, so we'll add on a few 0s
				content += "0"*(4-chars)
			if n == (n_words-1) and not i == (n_lines-1):
				#This means we're at the end of a line and are going to start a new one
				content += "\n\tdat "
			elif n == (n_words-1):
				#This means we're at the end of a line and are not going to start a new one
				content += "\n"
			else:
				#This means we're in the middle of a line
				content += ", "
			n += 1
		i += 1
	return content


def write_vfs_to_file(name):
	f = open(name, 'w')
	f.write(make_vfs())
	f.close()


def main():
	
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
		print "ERROR: Where's Atlas?"		
	if root == None:
		root = os.path.join(atlas, "misc", "vfs")
	
	#Make root directory -- we always need this
	directories[root] = 0
	make_table_entry({
		'directory': 0,
		'flags': Fdirectory,
		'name': make_name("/"),
		'labels': {'start': "0x0", 'end': "0x0"}
	})
	
	#Does the root directory exist?
	if not os.access(root, os.F_OK):
		write_vfs_to_file(os.path.join(atlas, "misc", "vfs.dasm16"))
		return 0
	
	#Go through every file in the (real) vfs directory
	directories_to_look_through = [root] #Subsequent directories will be vfs/dir1/dir2/...dirn
	i = 0
	while i < len(directories_to_look_through):
		stuff = os.listdir(directories_to_look_through[i])
		for item in stuff:
			fullpath = os.path.join(directories_to_look_through[i], item)
			if item[0] == '.':
				continue
			if os.path.isdir(fullpath):
				make_dir(directories_to_look_through[i], item)
				directories_to_look_through.append(fullpath)
			elif item[:-4] == ".bin":
				f = open(fullpath, 'rb')
				make_file(directories_to_look_through[i], Freadexe, item, f.read())
				f.close()
			else:
				f = open(fullpath, 'rb')
				make_file(directories_to_look_through[i], Freadwrite, item, f.read())
		i+=1
	
	write_vfs_to_file(os.path.join(atlas, "misc", "vfs.dasm16"))
	print "VFS Built"
	return 0


if __name__ == "__main__":
	exit(main())

