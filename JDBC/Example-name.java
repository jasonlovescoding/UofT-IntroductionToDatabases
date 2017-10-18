// A simple JDBC example.

// Remember that you need to put the jdbc postgresql driver in your class path
// when you run this code.
// See /local/packages/jdbc-postgresql on cdf for the driver, another example
// program, and a how-to file.

// To compile and run this program on cdf:
// (1) Compile the code in Example.java.
//     javac Example
// This creates the file Example.class.
// (2) Run the code in Example.class.
// Normally, you would run a Java program whose main method is in a class 
// called Example as follows:
//     java Example
// But we need to also give the class path to where JDBC is, so we type:
//     java -cp /local/packages/jdbc-postgresql/postgresql-8.4-701.jdbc4.jar: Example
// Alternatively, we can set our CLASSPATH variable in linux.  (See
// /local/packages/jdbc-postgresql/HelloPostgresql.txt on cdf for how.)

import java.sql.*;
import java.io.*;

class Example {
    
    public static void main(String args[]) throws IOException
        {
            String url;
            Connection conn;
            PreparedStatement pStatement;
            ResultSet rs;
            String queryString;

            try {
                Class.forName("org.postgresql.Driver");
            }
            catch (ClassNotFoundException e) {
                System.out.println("Failed to find the JDBC driver");
            }
            try
            {
                // This program connects to my database csc343h-dianeh,
                // where I have loaded a table called Guess, with this schema:
                //     Guesses(_number_, name, guess, age)
                // and put some data into it.
                
                // Establish our own connection to the database.
                // This is the right url, username and password for jdbc
                // with postgres on cdf -- but you would replace "dianeh"
                // with your cdf account name.
                // Password really does need to be the emtpy string.
                url = "jdbc:postgresql://localhost:5432/csc343h-zhan5612";
                conn = DriverManager.getConnection(url, "zhan5612", "");

                // Executing this query without having first prepared it
                // would be safe because the entire query is hard-coded.  
                // No one can inject any SQL code into our query.
                // But let's get in the habit of using a prepared statement.
                queryString = "select count(distinct name) from guesses";
                pStatement = conn.prepareStatement(queryString);
                rs = pStatement.executeQuery();
		int count = 0;
		String[] names = null;	
                // Iterate through the result set and report on each tuple. 
                while (rs.next()) {
			count = rs.getInt("count");
			names = new String[count];
                	System.out.println(String.format("%d names altogether.", count));
                }
                // The next query depends on user input, so we are wise to
                // prepare it before inserting the user input.
                queryString = "select distinct name from guesses";
                pStatement = conn.prepareStatement(queryString);
                rs = pStatement.executeQuery(); 

                // Iterate through the result set and report on each tuple.
                int idx = 0;
		while (rs.next()) {
                    String name = rs.getString("name");
                    // System.out.println(String.format("name %s", name));
                    names[idx] = name;
		    idx++;
		}
                idx = 0;
	 	while (idx < count) {
		    System.out.println(String.format("name %s", names[idx]));
		    idx++;
		}
            }
            catch (SQLException se)
            {
                System.err.println("SQL Exception." +
                        "<Message>: " + se.getMessage());
            }

        }
        
}
