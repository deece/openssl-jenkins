#!/usr/bin/env perl -w

/bits ecdsa \((.+)\) +[0-9.]+s +[0-9.]+s +([0-9.]+) +([0-9.]+)/ and do {
 	print("ecdsa $1 sign, $2\n");
 	print("ecdsa $1 verify, $3\n");
};

/bits ecdh \((.+)\) +[0-9.]+s +([0-9.]+)/ and do {
 	print("ecdh $1, $2\n");
};
