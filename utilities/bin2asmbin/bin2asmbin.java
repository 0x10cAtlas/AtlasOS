package net.plusmid.bin2asmbin;

import java.io.DataInputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;

public class Application {

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
		
		if (outputfile != null) {
			
			try {
				
				fw = new FileWriter(outputfile);

			} catch (IOException e) {
				
				fatal_error("could not write output file \"" + outputfile + "\"");
				
			}
			
		}
		
		try {
			
			while ((buffer = di.read()) != -1) {
				
				if ((buffer2 = di.read()) != -1)
					buffer |= (buffer2 << 8);
				
				if ((lines && (count % 8) == 0) || count == 0) {

					if (fw != null)
						fw.write("\ndat 0x" + Integer.toHexString(buffer));

					if (verbose)
						fw.write("\ndat 0x" + Integer.toHexString(buffer));

				} else {

					if (fw != null)
						fw.write(", 0x" + Integer.toHexString(buffer));
				
					if (verbose)
						System.out.print(", 0x" + Integer.toHexString(buffer));
				
					}

				++count;
			}
									
		} catch (IOException e) {
			
			error("unable to read file \"" + inputfile + "\"");
			
		}
		
		try {
			fi.close();
			di.close();
			if (fw != null)
				fw.close();
		} catch (IOException e) {
			
			error("unable to close filestream of \"" + inputfile + "\"");
			
		}
		
	}
	
	private static void parseCLI(String[] args) {
		
		for (int i=0; i<args.length; i++) {
			
			if (args[i].equals("-v") || args[i].equals("-verbose"))
				verbose = true;
			else if (args[i].equals("-l") || args[i].equals("-lines"))
				lines = true;
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
		
		System.out.println(
				"Usage:\n" +
				"bin2asmbin inputfile outputfile [arguments]\n" +
				"Arguments:\n" +
				"-v -verbose Prints the output on stdout (you may omit outputfile if using this).\n" +
				"-l -lines   Inserts a linefeed every 8 words.\n");
		
	}

}
