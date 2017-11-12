import java.util.List;
import java.sql.*; 
import java.util.ArrayList;

// Remember that an important part of your mark is for doing as much in SQL (not Java) as you can.
// Solutions that use only or mostly Java will not receive a high mark.
public class Assignment2 extends JDBCSubmission {
    public Assignment2() throws ClassNotFoundException {
        Class.forName("org.postgresql.Driver");
    }

    @Override
    public boolean connectDB(String url, String username, String password) {
      // Implement this method!
      try {
        this.connection = DriverManager.getConnection(url, username, password);
        System.out.println("DB connection established.");  
        return true;
      } catch (Exception e) {
        e.printStackTrace();
        return false;
      }
    }

    @Override
    public boolean disconnectDB() {
       if (this.connection != null) {
          try {
            this.connection.close();
            this.connection = null;
            System.out.println("DB connection successfully closed.");
            return true;
          } catch (Exception e) {
            e.printStackTrace();
            return false;
          }
        } else {
          System.out.println("DB connection already closed.");
          return true;
        }
    }

    @Override
    public ElectionCabinetResult electionSequence(String countryName) {
      List<Integer> elections = new ArrayList<Integer>();
      List<Integer> cabinets = new ArrayList<Integer>();
      String query;
      PreparedStatement ps;
      ResultSet rs;
      int cabinetId, electionId;
      // Implement this method!
      query = "select cabinet.id, cabinet.election_id" 
            + " from cabinet join election on cabinet.election_id = election.id" 
            + " join country on election.country_id = country.id" 
            + " where country.name = ?" 
            + " order by e_date desc"; 
      try {
        ps = this.connection.prepareStatement(query);
        ps.setString(1, countryName);
        rs = ps.executeQuery(); 
        while (rs.next()) {
          cabinets.add(rs.getInt("id"));
          elections.add(rs.getInt("election_id"));
        }
      } catch (SQLException e) {
        e.printStackTrace();
        return null;
      } 
      return new ElectionCabinetResult(elections, cabinets); 
    }

    @Override
    public List<Integer> findSimilarPoliticians(Integer politicianName, Float threshold) {
        List<Integer> presidents = new ArrayList<Integer>();
        PreparedStatement ps;
        ResultSet rs;
        String query1,query2;
        String politicianDescription;
        // Implement this method!
        query1 = "select description"
               + "from politician_president"
               + "where id = ? ;"
        try{
        	ps = this.connection.prepareStatement(query1);
        	ps.setString(1,politicianName);
        	rs = ps.executeQuery();
        	politicianDescription = rs.getString("description");
        } catch (SQLException e) {
          e.printStackTrace();
          return null;
      }
        query2 = "select id, description"
               + "from politician_president"
               + "where similarity(?,description) > ?"
               + "and id <> ? ;"
        try{
        	ps = this.connection.prepareStatement(query2);
        	ps.setString(1,politicianDescription);
        	ps.setString(2,threshold);
        	ps.setString(3, politicianName);
        	rs = ps.executeQuery();
        	while(rs.next())
        		presidents.add(rs.getInt("id"));
        } catch (SQLException e) {
          e.printStackTrace();
          return null;
      } 
        return presidents;
    }

    public static void main(String[] args) {
      // You can put testing code in here. It will not affect our autotester.
      try {
        Assignment2 a = new Assignment2();
        boolean v1 = a.connectDB("jdbc:postgresql://localhost:5432/csc343h-zhan5612?currentSchema=parlgov",
            "zhan5612", "");
        if (!v1) {
          System.out.println("connection error");
          return;
        }
        System.out.println(a.electionSequence("Canada"));
      } catch (Exception e) {
        e.printStackTrace();
      }
    }

}

