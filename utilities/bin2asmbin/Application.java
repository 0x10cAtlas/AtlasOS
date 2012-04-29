package net.plusmid.bin2asmbin;

import java.io.BufferedWriter;
import java.io.DataInputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;

public class Application {

	private final static int MAJOR = 0;
	private final static int MINOR = 1;
	private final static int REV   = 1;
	
	static String  inputfile  = null;
	static String  outputfile = null;
	static boolean verbose    = false;
	static boolean lines      = false;
	
	public static void main(String[] args) {

		// check if no arguments are provided
		if (args.length == 0) {
			showHelp();
			System.exit(1);
		}
		
		// parse command line arguments
		parseCLI(args);
		
		FileInputStream     fi = null;
		DataInputStream     di = null;
		
		try {
			
			// open input file
			fi = new FileInputStream(inputfile);
			di = new DataInputStream(fi);

		} catch (FileNotFoundException e) {
			
			fatal_error("could not find file \"" + inputfile + "\"");
			
		}
		
		int buffer = 0;
		int buffer2 = 0;
		int count  = 0;
		
		FileWriter fw = null;
		BufferedWriter bw = null;
		
		if (outputfile != null) {
			
			try {
				
				fw = new FileWriter(outputfile);
				bw =  new BufferedWriter(fw);
				
			} catch (IOException e) {
				
				fatal_error("could not write output file \"" + outputfile + "\"");
				
			}
			
		}
		
		try {
			
			while ((buffer = di.read()) != -1) {
				
				if ((buffer2 = di.read()) != -1)
					buffer |= (buffer2 << 8);
				
				if ((lines && (count % 8) == 0) || count == 0) {

					if (bw != null)
						bw.write("\ndat 0x" + toHex(buffer));

					if (verbose)
						bw.write("\ndat 0x" + toHex(buffer));

				} else {

					if (fw != null)
						bw.write(", 0x" + toHex(buffer));
				
					if (verbose)
						System.out.print(", 0x" + toHex(buffer));
				
					}

				++count;
			}
									
		} catch (IOException e) {
			
			error("unable to read file \"" + inputfile + "\"");
			
		}
		
		try {
			fi.close();
			di.close();
			if (bw != null)
				bw.close();
			if (fw != null)
				fw.close();
		} catch (IOException e) {
			
			error("unable to close filestream of \"" + inputfile + "\"");
			
		}
		
	}
	
	private static String toHex(int value) {

		String buffer = Integer.toHexString(value);
		
		while (4 - buffer.length() > 0)
			buffer = "0" + buffer;
		
		return buffer;
		
	}
	
	private static void parseCLI(String[] args) {
		
		for (int i=0; i<args.length; i++) {
			
			if (args[i].equals("-v") || args[i].equals("-verbose"))
				verbose = true;
			else if (args[i].equals("-l") || args[i].equals("-lines"))
				lines = true;
			else if (args[i].equals("-ver") || args[i].equals("-version"))
				showVersion(true);
			else if (inputfile == null)
				inputfile = args[i];
			else if (outputfile == null)
				outputfile = args[i];
			else
				error("unrecognized command \"" + args[i] + "\"");
			
		}
		
		if (inputfile == null)
			fatal_error("no input file specified!");
		
		if (outputfile == null && verbose == false)
			fatal_error("no output file specified!");
		
	}

	private static void fatal_error(String msg) {
		
		say("fatal error: " + msg);
		showHelp();
		System.exit(1);
		
	}
	
	private static void error(String msg) {
		
		say("error: " + msg);
		
	}

	private static void say(String msg) {
		
		System.err.println(msg);
		
	}

	private static void showHelp() {
		
		showVersion();
		
		System.out.println(
				"Usage:\n" +
				"bin2asmbin inputfile outputfile [arguments]\n" +
				"Arguments:\n" +
				"-v -verbose Prints the output on stdout (you may omit outputfile if using this).\n" +
				"-l -lines   Inserts a linefeed every 8 words.\n" +
				"-ver -version Shows the version of this application.");
		
	}
	
	private static void showVersion(boolean exit) {
		
		System.out.println(
				"bin2asmbin v" + MAJOR + "." + MINOR + "." + REV);
		
		if (exit)
			System.exit(0);
		
	}
	
	private static void showVersion() {
		
		showVersion(false);
		
	}

}
