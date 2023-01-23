# A CSV-iterator tool for Mac OS X

This is a tool that I use to iterate through the rows of a CSV file.

## Requirements

- Mac OS X (tested on Ventura 13.0.1)
- OCaml (tested on version 4.13.1)
- Apple Numbers

## Assumptions

I assume you have a CSV file generated from an Apple Numbers spreadsheet. I mention Apple Numbers because CSV is a surprisingly unstandardised format, and my tool is quite specialised for the dialect of CSV that Apple Numbers exports. Other CSV files might or might not work. In particular:

- values are comma-separated (as you would expect),
	
- values that do (or could) contain commas or newlines are wrapped in double-quotes,
	
- but empty values are not wrapped in double-quotes,
	
- double-quotes that appear inside values are replaced with two consecutive double-quotes (so "this is an ""example"" of a valid value")

## Getting started

Run `make`.

This repo includes a sample CSV file. To use it to see how the tool works, run the following command:

    ./csv_iterator -csv database.csv -cmd "echo \$firstname got \$percent%."

## What the tool does
		
1. The tool creates a new file called `database.csv.tmp` in which `""` has been globally replaced with `”`. This makes a Numbers-generated CSV file easier to parse (see note above).
 
2. For each non-header row of `database.csv.tmp`, the tool runs `field1=v1 ... fieldN=vN eval 'command'`, where `field1`, ..., `fieldN` are the column names of the CSV file and `v1`, ..., `vN` are the values taken by those fields in the current row. In other words, the command `command` is run in a shell where the current row's values have been assigned to environment variables of the same name.
 
3. You can set the `-dryrun` flag so that the commands to be run are printed to the terminal but not actually executed.

4. If you set the `-onlyfirstrow` flag, the tool will stop after the first (non-header) row. This can be useful when testing.

Note:

- I wrote `\$firstname` rather than `$firstname` above in order to prevent the `firstname` variable from being expanded when calling `csv_iterator`. It should only be expanded when the generated commands are executed.

- Best avoid having backticks in the CSV file, as Bash might see those as commands to be executed.
