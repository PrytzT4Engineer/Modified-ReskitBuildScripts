using System;

namespace Game
{
    class Ordklassberättelser
    {
        // Variabler // Siffrorna på rad 8 ska ALLTID vara en högre än Ord[x]
        static string[] Ord = new string[] { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" };
        static string[] Ordklass = new string[] { "namn", "adjektiv", "adjektiv", "adjektiv", "adjektiv", "adjektiv", "adjektiv", "adjektiv", "adjektiv", "adjektiv" };
        static string Berättelse;

        public static void Run()
        {
            Start();
            GetOrd();
            Skrivberättelse();
            Slut();
        }

        static void Start()
        {
            // Titel på programmet
            Console.Title = "Ordklassberättelser";

            // Färgen på välkomst meddelandet
            Console.ForegroundColor = ConsoleColor.Blue;

            string text1 = @"
██    ██  █████  ██      ██   ██  ██████  ███    ███ ███    ███ ███████ ███    ██ 
██    ██ ██   ██ ██      ██  ██  ██    ██ ████  ████ ████  ████ ██      ████   ██ 
██    ██ ███████ ██      █████   ██    ██ ██ ████ ██ ██ ████ ██ █████   ██ ██  ██ 
 ██  ██  ██   ██ ██      ██  ██  ██    ██ ██  ██  ██ ██  ██  ██ ██      ██  ██ ██ 
  ████   ██   ██ ███████ ██   ██  ██████  ██      ██ ██      ██ ███████ ██   ████ ";

            string text2 = @"
████████ ██ ██      ██      
   ██    ██ ██      ██      
   ██    ██ ██      ██      
   ██    ██ ██      ██      
   ██    ██ ███████ ███████ ";

            string text3 = @"
███    ███  █████  ██████  ██      ██ ██████  ███████ 
████  ████ ██   ██ ██   ██ ██      ██ ██   ██ ██      
██ ████ ██ ███████ ██   ██ ██      ██ ██████  ███████ 
██  ██  ██ ██   ██ ██   ██ ██      ██ ██   ██      ██ 
██      ██ ██   ██ ██████  ███████ ██ ██████  ███████ ";
                                                      
            // Skriver "Välkommen"
            Console.Write(text1);
            Console.ReadLine();
            Console.Clear();

            // Skriver "Till"
            Console.Write(text2);
            Console.ReadLine();
            Console.Clear();

            // Skriver "Madlibs"
            Console.Write(text3);
            Console.ReadLine();

            // Skriver "På svenska"
            Console.WriteLine("(På svenska)");
            Console.ReadLine();
            Console.Clear();
        }

        static void GetOrd()
        {
            // Frågar spelaren att mata in ord
            for (int i = 0; i < Ord.Length; i++)
            {
                Console.Write("Skriv en/ett " + Ordklass[i] + ": ");
                Ord[i] = Console.ReadLine();
            }

            // Rensar all text i konsolen
            Console.Clear();
        }

        static void Skrivberättelse()
        {
            Console.ForegroundColor = ConsoleColor.Green;
            // Skriver ut berättelsen "\n" betyder ny rad
            // 0 = namn, 1 = pronomen (han/hon), 2 = djur, 3 = verb (dåtid), 4 = adverb, 5 = adjektiv, 6 = adjketiv, 7 = substantiv, 
            Berättelse = "Idag gick {0} till ett zoo, där såg {1} en/ett {2} som hoppade upp och ner i sitt träd. Djuret {3} {4} genom den {5} tunneln som leder till djurets {6} {7}.\n {0} hade jordnötter {8} {9}";
            Console.WriteLine(Berättelse, Ord[0], Ord[1], Ord[2], Ord[3], Ord[4], Ord[5], Ord[6], Ord[7], Ord[8], Ord[9]);

        }
        static void Slut()
        {
            // Hejdå meddelande
            Console.ForegroundColor = ConsoleColor.Blue;
            Console.WriteLine("Klicka på valfri knapp för att lämna");
            Console.ReadKey();
        }
    }
    class Program
    {
        static void Main()
        {
            Ordklassberättelser.Run();
        }
    }
}