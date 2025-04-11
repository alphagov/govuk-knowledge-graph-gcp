#define _POSIX_C_SOURCE 200809L // For getline
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h> // For bool type

#define MAX_TABLE_NAME_LEN 256 // Define a reasonable max length for table names

int main(int argc, char *argv[]) {
    // --- Argument Handling ---
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <target_table_name>\n", argv[0]);
        fprintf(stderr, "Reads SQL dump from stdin, extracts data for the specified table,\n");
        fprintf(stderr, "and outputs CSV-like data to stdout.\n");
        return 1;
    }
    const char *target_table_name = argv[1];
    size_t target_table_len = strlen(target_table_name);
    // --- End Argument Handling ---

    char *line = NULL;
    size_t len = 0;
    ssize_t read;

    // State variable to track if we are processing the target table's INSERTs
    bool processing_target_table = false;
    char current_table_name[MAX_TABLE_NAME_LEN] = {0}; // Buffer for table name extracted from lines

    const char *dumping_prefix = "-- Dumping data for table `"; // More specific prefix
    const char *insert_prefix = "INSERT INTO `";           // Note the backtick

    while ((read = getline(&line, &len, stdin)) != -1) {

        // Check for "-- Dumping data for table" line
        if (strncmp(line, dumping_prefix, strlen(dumping_prefix)) == 0) {
            char *start_quote = line + strlen(dumping_prefix); // Start after the prefix
            char *end_quote = strchr(start_quote, '`');
            if (end_quote) {
                size_t table_name_len = end_quote - start_quote;
                if (table_name_len < sizeof(current_table_name) - 1) {
                    strncpy(current_table_name, start_quote, table_name_len);
                    current_table_name[table_name_len] = '\0'; // Null terminate

                    // Check if this is the table we're interested in
                    if (table_name_len == target_table_len && strcmp(current_table_name, target_table_name) == 0) {
                        processing_target_table = true;
                        fprintf(stderr, "Info: Found target table section: %s\n", target_table_name);
                    } else {
                        // If we encounter a dump line for a *different* table, stop processing
                        // in case we were processing the target table before.
                        if (processing_target_table) {
                          fprintf(stderr, "Info: Subsequent table section found, processing will stop: %s\n", target_table_name);
                          break;
                        }
                    }
                } else {
                     fprintf(stderr, "Warning: Extracted table name too long in dumping line: %.*s\n", (int)table_name_len, start_quote);
                     processing_target_table = false; // Cannot be the target if too long
                }
            } else {
                 fprintf(stderr, "Warning: Malformed dumping line (no closing backtick): %s", line);
                 processing_target_table = false; // Unsure, assume not target
            }
            continue; // Skip to the next line
        }

        // Check for "INSERT INTO" line - only process if the flag is set
        if (processing_target_table && strncmp(line, insert_prefix, strlen(insert_prefix)) == 0) {

            // Find where the actual data values start
            char *values_ptr = strstr(line, " VALUES "); // Standard space
             if (!values_ptr) {
                 fprintf(stderr, "Warning: Could not find ' VALUES ' pattern in INSERT line for target table: %s", line);
                 continue; // Skip malformed line
             }

            size_t start_of_data = (values_ptr - line) + strlen(" VALUES "); // Start at the opening parenthesis

            // Initialize state variables for parsing values
            bool p = false; // is_within_parentheses of a *tuple*
            bool q = false; // is_within_quotes
            bool b = false; // is_preceded_by_backslash (for the *next* character)

            // Loop through characters starting from the data
            // Use 'read - 1' to potentially exclude the trailing newline read by getline
            size_t line_len = strlen(line);
            if (line[line_len - 1] == '\n') {
                line_len--; // Don't process the newline character itself
            }

            for (size_t i = start_of_data; i < line_len; i++) {
                char char_current = line[i];

                // Store the backslash state relevant *for this character*
                bool was_escaped = b;
                // Reset backslash flag for the *next* character by default
                b = false;

                // Check for an *unescaped* backslash first.
                if (char_current == '\\' && !was_escaped) {
                    b = true;    // Set flag: the *next* character is preceded by a backslash
                    continue;   // Go to the next character (effectively skipping this '\')
                }

                // Unescaped single quote toggles is_within_quotes state and prints a double quote.
                if (char_current == '\'' && !was_escaped) {
                    q = !q;     // Flip the is_within_quotes state
                    if (fputc('"', stdout) == EOF) {
                         perror("fputc '\"' failed"); goto write_error;
                    }
                    continue;   // Go to the next character
                }

                // Double quote is doubled and written to the file.
                if (char_current == '"') {
                     if (fputc('"', stdout) == EOF || fputc('"', stdout) == EOF) {
                         perror("fputc double '\"' failed"); goto write_error;
                    }
                    continue;   // Go to the next character
                }

                // Comma outside parentheses is skipped.
                if (char_current == ',' && !p) { // Check if char is comma AND is_within_parentheses is FALSE
                    continue;   // Go to the next character
                }

                // Open parenthesis when *not* already in parentheses.
                // Sets state and skips printing the parenthesis.
                if (char_current == '(' && !p) {
                    p = true;   // Set is_within_parentheses to TRUE
                    continue;   // Go to the next character
                }

                // Close parenthesis when *not* within quotes.
                // Resets state, prints a newline, and skips printing the parenthesis.
                if (char_current == ')' && !q) { // Check if char is ')' AND is_within_quotes is FALSE
                    p = false;  // Set is_within_parentheses to FALSE
                    if (fputc('\n', stdout) == EOF) {
                        perror("fputc newline failed"); goto write_error;
                    }
                    continue;   // Go to the next character
                }

                 // Discard a final semicolon if not within quotes (often marks end of INSERT)
                 if (char_current == ';' && !q) {
                     continue; // Go to the next character
                 }

                // Write the character to the file.
                // This rule executes if none of the 'continue' statements above were triggered.
                if (fputc(char_current, stdout) == EOF) {
                    perror("fputc char failed"); goto write_error;
                }
            } // End character loop
        } // End INSERT INTO block for the target table
    } // End while getline

    fprintf(stderr, "Info: The end of the file has been reached, processing will stop: %s\n", target_table_name);

    // Clean up
    free(line); // Free memory allocated by getline

    // Flush stdout buffer to ensure everything is written
    if (fflush(stdout) == EOF) {
        perror("fflush stdout failed at end");
        return 1; // Indicate error on final flush
    }

    return 0; // Indicate success

write_error: // Label for handling write errors during character processing
    fprintf(stderr, "Error occurred while writing to stdout.\n");
    free(line); // Free memory allocated by getline
    return 1; // Indicate failure
}
