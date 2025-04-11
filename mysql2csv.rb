#!/usr/bin/env ruby
# encoding: utf-8

# Convert each table in a mysql/mariadb SQL dump file to CSV
# for uploading to BigQuery.
# Replicates the logic of the provided awk script.

require 'stringio' # Used for IO.popen alternative if needed, but IO.popen is fine.
require 'shellwords'

current_gzip_filename = nil
outfile_io = nil

# Regex to find the start of data dump for a table
dumping_regex = /^-- Dumping data for table `([^`]*)`$/
# Regex to find the start of an INSERT statement values list
insert_regex = /^INSERT INTO `[^`]*` VALUES /

# Process input line by line from stdin or files specified as arguments
ARGF.set_encoding('UTF-8') # Assume UTF-8 input as requested
ARGF.each_line do |line|
  # Check if the line indicates the start of data for a new table
  if match = line.match(dumping_regex)
    table_name = match[1]
    gzip_filename = table_name + ".gz"
    STDERR.puts "Processing table and writing to: #{gzip_filename}"

    # Close the previous output pipe if it's open
    outfile_io&.close # Use safe navigation (&.) in case it's nil

    # The awk script checks and wipes the non-gzipped file, which seems
    # unnecessary as it immediately pipes to gzip. We will skip that step
    # and directly open the pipe, which will overwrite or create the .gz file.
    # system("[ -e \"#{table_name}\" ] && > \"#{table_name}\"") # Equivalent awk system call, but skipped

    # Open a pipe to gzip for writing the compressed output
    begin
      # Ensure filename is properly quoted for the shell command
      quoted_gzip_filename = Shellwords.escape(gzip_filename)
      outfile_io = IO.popen("gzip > #{quoted_gzip_filename}", "w:UTF-8") # Write in UTF-8
      current_gzip_filename = gzip_filename
    rescue => e
      STDERR.puts "Error opening pipe to gzip for #{gzip_filename}: #{e.message}"
      outfile_io = nil # Ensure it's nil so we don't try to write later
    end
    next # Move to the next line of input

  # Check if the line is an INSERT statement *and* we have an active output file
  elsif outfile_io && line.start_with?('INSERT INTO') && line.match(insert_regex)
    # Extract the data part (everything after "VALUES ")
    # Using match and post_match is robust
    match_data = line.match(insert_regex)
    rest_of_line = match_data.post_match if match_data

    # If for some reason post_match failed (shouldn't happen with start_with?), skip
    next unless rest_of_line

    # Initialize state variables
    is_within_parentheses = false # awk 'p'
    is_within_quotes = false      # awk 'q'
    is_escaped = false            # awk 'b' (tracks if the *next* char is escaped)

    # Process the data part character by character
    rest_of_line.each_char do |char|
      # Store the backslash state relevant *for this character*
      was_preceded_by_backslash = is_escaped
      # Reset backslash flag for the *next* character by default
      is_escaped = false

      # 1. Check for an *unescaped* backslash.
      #    Sets flag for the next character, skip printing this backslash.
      if char == '\\' && !was_preceded_by_backslash
        is_escaped = true # Flag the *next* character as escaped
        next              # Skip processing/printing this backslash
      end

      # 2. Unescaped single quote: Toggle state, print double quote for CSV.
      if char == "'" && !was_preceded_by_backslash
        is_within_quotes = !is_within_quotes
        outfile_io.print '"'
        next
      end

      # 3. Double quote: Double it for CSV compatibility.
      #    This handles cases where data might *contain* double quotes,
      #    although standard SQL dump escapes them differently ('').
      #    This exactly replicates the awk script's behavior.
      if char == '"'
         # Note: If the input SQL uses standard SQL escaping like '' for a single quote,
         # this script (and the original awk) might not handle it as intended.
         # It assumes MySQL's default backslash escaping.
         outfile_io.print '""' # Double the double quote
         next
      end

      # --- Logic based on state (parentheses/quotes) ---

      # 4. Comma outside parentheses: Skip (acts as value separator in INSERT)
      if char == ',' && !is_within_parentheses
        next
      end

      # 5. Open parenthesis: Enter parenthesized state (start of a row tuple)
      #    Only triggers on the first opening parenthesis of a tuple.
      if char == '(' && !is_within_parentheses
        is_within_parentheses = true
        next # Skip printing the parenthesis
      end

      # 6. Close parenthesis *when not within quotes*: Exit parenthesized state (end of a row tuple)
      #    Print a newline for CSV row end.
      if char == ')' && !is_within_quotes
        is_within_parentheses = false
        outfile_io.print "\n" # End of CSV row
        next # Skip printing the parenthesis
      end

      # 7. Semicolon *when not within quotes*: Skip (end of INSERT statement)
      if char == ';' && !is_within_quotes
        next
      end

      # 8. Default: Write the character to the output file.
      #    This handles regular data characters, commas within quotes or parentheses,
      #    and characters that were preceded by a backslash (since the backslash itself was skipped).
      outfile_io.print char

    end # each_char loop
  end # if/elsif line type check
end # ARGF.each_line loop

# Ensure the last opened file pipe is closed
outfile_io&.close
