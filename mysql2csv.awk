#!/usr/bin/awk -f

# Convert each table in a mysql/mariadb SQL dump file to CSV for uploading to BigQuery.

BEGIN {
  # Process character by character
  FS = "";
  # Set Output Field Separator and Record Separator to empty
  # to control output precisely via printf
  OFS = "";
  ORS = "";
}

/^-- Dumping/ {
  match($0, /`([^`]*)`/)
  filename = substr($0, RSTART + 1, RLENGTH - 2)
  gzip_filename = filename ".gz"
  print "Processing table and writing to:", gzip_filename

  # Close the file, if it happens to be open
  close(outfile)

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

      # Store the backslash state relevant *for this character*
      was_escaped = b;
      # Reset backslash flag for the *next* character by default
      b = 0;

      # Check for an *unescaped* backslash first.
      # If it is one, set the flag for the next character and skip printing this one.
      if (char == "\\" && !was_escaped) {
          b = 1;      # Set flag: the *next* character is preceded by a backslash
          continue;   # Go to the next character (effectively skipping this '\')
      }

      # Unescaped single quote toggles is_within_quotes state. and prints a double quote.
      if (char == "'" && !was_escaped) {
          q = !q;     # Flip the is_within_quotes state
          printf "%s", "\"" | outfile
          continue;   # Go to the next character
      }

      # Double quote is doubled and written to the file.
      if (char == "\"") {
          printf "%s", char | outfile
          printf "%s", char | outfile
          continue;   # Go to the next character
      }

      # Comma outside parentheses is skipped.
      if (char == "," && !p) { # Check if char is comma AND is_within_parentheses is FALSE
          continue;   # Go to the next character
      }

      # Open parenthesis when *not* already in parentheses.
      # Sets state and skips printing the parenthesis.
      if (char == "(" && !p) {
          p = 1;      # Set is_within_parentheses to TRUE
          continue;   # Go to the next character
      }

      # Close parenthesis when *not* within quotes.
      # Resets state, prints a newline, and skips printing the parenthesis.
      if (char == ")" && !q) { # Check if char is ')' AND is_within_quotes is FALSE
          p = 0;      # Set is_within_parentheses to FALSE
          printf "\n" | outfile # Write a newline character to
          continue;   # Go to the next character
      }

      # Discard a final semicolon
      if (char == ";" && !q) { # Check if char is ';' AND is_within_quotes is FALSE
          continue;   # Go to the next character
      }

      # Write the character to the file.
      # This rule executes if none of the 'continue' statements above were triggered.
      printf "%s", char | outfile
  }
}
