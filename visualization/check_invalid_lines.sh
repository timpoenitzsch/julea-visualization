#!/bin/bash

# Define file
FILE="../benchmark_csv_total/benchmark_total.csv"

# Check each line of the file
awk -F',' '
NR > 1 {
    name=$1;
    elapsed=$2;
    operations=$3;
    bytes=$4;
    total_elapsed=$5;
    timestamp=$6;

    # check elapsed
    if (elapsed !~ /^[0-9]+(\.[0-9]+)?$/) {
        print "Ungültige Zeile " NR ": " $0 " (elapsed ungültig)"
    }

    # check operations (muss Zahl sein)
    else if (operations !~ /^[0-9]+(\.[0-9]+)?$/) {
        print "Ungültige Zeile " NR ": " $0 " (operations ungültig)"
    }

    # check bytes ('-' is allowed)
    else if (bytes != "-" && bytes !~ /^[0-9]+(\.[0-9]+)?$/) {
        print "Ungültige Zeile " NR ": " $0 " (bytes ungültig)"
    }

    # check total_elapsed (muss Zahl sein)
    else if (total_elapsed !~ /^[0-9]+(\.[0-9]+)?$/) {
        print "Ungültige Zeile " NR ": " $0 " (total_elapsed ungültig)"
    }

    # check timestamp (muss Zahl sein)
    else if (timestamp !~ /^[0-9]+$/) {
        print "Ungültige Zeile " NR ": " $0 " (timestamp ungültig)"
    }

}' "$FILE"