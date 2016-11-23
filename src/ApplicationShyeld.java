import java.sql.*;
import java.util.Scanner;

public class ApplicationShyeld {

	public static void main(String[] args) {
		Scanner scanner = new Scanner(System.in);
		DataBaseAccess db = new DataBaseAccess();
		System.out.println("Bienvenue dans l'applicaton centrale du SHYELD");
		System.out.println("1: Inscription d'un agent");
		System.out.println("2: Suppression d'un agent");
		System.out.println("3: Information de perte de visibilite des super-hero");
		System.out.println("4: Suppression d'un super-hero");
		System.out.println("5: Zones à risques");
		System.out.println("6: Historique des relevés");
		System.out.println("7: Statistiques");
		int choix;
		do{
			choix = scanner.nextInt();
		}
		while(choix < 1 || choix > 7);
		
		switch (choix) {
		case 1:
			System.out.println("Entrez le prenom de l'agent");
			String prenom = scanner.next();
			System.out.println("Entrez le nom de l'agent");
			String nom = scanner.next();
			if(InscriptionAgent(db, nom, prenom)){
				System.out.println("l'agent " + nom + " " + prenom + " à été ajouté");
			}
			else{
				System.out.println("Erreur");
			}
			break;
			
		case 2:
			System.out.println("Entrez le prenom de l'agent");
			prenom = scanner.next();
			System.out.println("Entrez le nom de l'agent");
			nom = scanner.next();
			if(SuppressionAgent(db, nom, prenom)){
				System.out.println("l'agent " + nom + " " + prenom + " à été supprimé");
			}
			else{
				System.out.println("Erreur");
			}
			break;
			
		case 3:
			
			break;
		default:
			break;
		}
	}
	
	public static boolean InscriptionAgent(DataBaseAccess db, String nom, String prenom){
		
		return false;
	}
	
	public static boolean SuppressionAgent(DataBaseAccess db, String nom, String prenom){
		
		return false;
	}
}
