import java.sql.*;

public class DataBaseAccess {
	private Connection conn = null;
	
	public DataBaseAccess(){
		/*
		 * Chargement du driver postgresql
		 */
		try {
			Class.forName("org.postgresql.Driver");
		}
		catch (ClassNotFoundException e) {
			System.out.println("Driver PostgreSQL manquant !");
			System.exit(1);
		}
		System.out.println("Driver charg�");
		
		/*
		 * 	Connexion au serveur de la base de donn�e
		 */
		String url="jdbc:postgresql://localhost:5432/Projet?user=postgres&password=azerty";	
		try {
			conn=DriverManager.getConnection(url);
		} 
		catch (SQLException e) {
			System.out.println("Impossible de joindre le server !");
			System.exit(1);
		}
		System.out.println("Connexion avec la Base de donn�e �tablie");	
	}

	public Connection getConn() {
		return conn;
	}

	public void setConn(Connection conn) {
		this.conn = conn;
	}
	
}
