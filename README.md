# md5 3SI3


# Fonctionnalités
Initialisation du Contexte MD5 : 
Les valeurs initiales de l'état MD5 sont chargées dans le tableau state.

Exemple de Message : 
Le message "abcd" est chargé dans le buffer msg.
Calcul de la Longueur du Message : La longueur du message est calculée et stockée dans count.

Padding du Message : 
Le message est rempli avec des bits 0 jusqu'à ce que la longueur soit congruente à 448 bits modulo 512. Un bit '1' est ajouté après la fin du message original.
Ajout de la Longueur du Message en Bits : La longueur du message en bits est ajoutée à la fin du message après le padding.

Transformation MD5 : 
Les blocs de message sont traités dans la fonction md5_transform.
Affichage du Hash : Le hash MD5 calculé est converti en hexadécimal et affiché.


# Explication du Code
Section .data
Contient les valeurs initiales, le padding et les constantes nécessaires pour l'algorithme MD5.

Section .bss
Déclare les buffers et variables nécessaires pour le calcul du hash.

Section .text
Contient le code principal du programme, y compris l'initialisation, le padding, la transformation MD5 et l'affichage du hash.

_start
Point d'entrée principal du programme. Initialise le contexte MD5, charge un exemple de message, effectue le padding, appelle la transformation MD5 et affiche le hash.

md5_transform
Effectue les transformations MD5 sur les blocs de message.

md5_decode
Convertit les 64 octets du message en mots de 32 bits.

print_hash
Convertit et affiche l'état MD5 (A, B, C, D) en hexadécimal.

print_hex
Convertit une valeur en hexadécimal et l'affiche.
