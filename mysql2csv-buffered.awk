#!/usr/bin/awk -f

# Convert each table in a mysql/mariadb SQL dump file to CSV for uploading to BigQuery.
# Buffers output to avoid potential issues with large INSERT statements.

BEGIN {
  # Process character by character
  FS = "";
  # Set Output Field Separator and Record Separator to empty
  # to control output precisely via printf
  OFS = "";
  ORS = "";

  buffer_length = 0
  buffer_limit = 2**15 # Don't exceed ULONG_MAX
  buffer = ""
}

function flush_buffer(file) {
  print buffer | file
  buffer = ""
  buffer_length = 0
}

/^-- Dumping/ {
  if (outfile) {
    flush_buffer(outfile)
    close(outfile)
  }

  match($0, /`([^`]*)`/)
  filename = substr($0, RSTART + 1, RLENGTH - 2)
  gzip_filename = filename ".gz"
  print "Processing table and writing to:" gzip_filename "\n"

  # Open a pipe to gzip to write to the gzipped file
  outfile = "gzip > \"" gzip_filename "\""
  next
}

/^INSERT/ {
  start_of_data = 23 + length(filename) # "INSERT INTO `<filename>` VALUES "

  # Initialize state variables (0 for FALSE, 1 for TRUE)
  p = 0; # is_within_parentheses
  q = 0; # is_within_quotes
  b = 0; # is_preceded_by_backslash (for the *next* character)

  # Loop through each character (field) in the current line (record)
  for (i = start_of_data; i <= NF; i++) {
    char = $i;

    if (buffer_length == buffer_limit) {
      flush_buffer(outfile)
    }

    # Store the backslash state relevant *for this character*
    was_escaped = b;
    # Reset backslash flag for the *next* character by default
    b = 0;

    # Check for an *unescaped* backslash first.
    # If it is one, set the flag for the next character and skip printing this one.
    if (char == "\\" && !was_escaped) {
      b = 1;     # Set flag: the *next* character is preceded by a backslash
      continue;    # Go to the next character (effectively skipping this '\')
    }

    # Unescaped single quote toggles is_within_quotes state. and prints a double quote.
    if (char == "'" && !was_escaped) {
      q = !q;     # Flip the is_within_quotes state
      buffer = buffer "\""
      buffer_length = buffer_length + 1
      continue;    # Go to the next character
    }

    # Double quote is doubled and written to the file.
    if (char == "\"") {
      buffer = buffer char char
      buffer_length = buffer_length + 2
      continue;    # Go to the next character
    }

    # Comma outside parentheses is skipped.
    if (char == "," && !p) { # Check if char is comma AND is_within_parentheses is FALSE
      continue;    # Go to the next character
    }

    # Open parenthesis when *not* already in parentheses.
    # Sets state and skips printing the parenthesis.
    if (char == "(" && !p) {
      p = 1;     # Set is_within_parentheses to TRUE
      continue;    # Go to the next character
    }

    # Close parenthesis when *not* within quotes.
    # Resets state, adds a newline to the buffer, and skips printing the parenthesis.
    if (char == ")" && !q) { # Check if char is ')' AND is_within_quotes is FALSE
      p = 0;     # Set is_within_parentheses to FALSE
      buffer = buffer "\n" # Write a newline character to the buffer
      buffer_length = buffer_length + 1
      continue;    # Go to the next character
    }

    # Discard a final semicolon
    if (char == ";" && !q) { # Check if char is ';' AND is_within_quotes is FALSE
      continue;    # Go to the next character
    }

    # Append the character to the buffer.
    buffer = buffer char
    buffer_length = buffer_length + 1
  }
}

END {
  # Flush any remaining data in the buffer at the end
  flush_buffer(outfile)
  close(outfile)
}
