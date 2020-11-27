#!/bin/bash

#########################################
#
#-- Delete all necessary for Harbor
#
#-- Author: Cormac J. Hogan
#
#-- Version 1.0 (06-Nov-2020)
#
#########################################

clear

echo
echo "*************************************************************"
echo "***                                                       ***"
echo "*** Script to delete CA cert and private key, server CSR, ***"
echo "*** x509 ext file, and certs for Harbor and Docker        ***"
echo "***                                                       ***"
echo "*************************************************************"
echo

function check_deps()
{
	which openssl > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		echo "openssl is not installed, or is not in the PATH, exiting ..."
		exit
	fi
}

echo "-- Step 0: Checking dependencies ..."
check_deps

echo
echo "Type in the fully qualified domain name of the harbor registry (e.g. harbor.vmware.com)..."
read fqdn

if [ -z "$fqdn" ]
then
	echo "no fqdn supplied"
	exit
fi

echo
echo "*** Script to delete CA cert and private key, server CSR, x509 ext file, and certs for Harbor and Dcoker ***"
echo
echo "Hit enter to continue";read null
echo
echo "Step 1 - Delete the CA Cert and Key in local directory"
echo
 sudo rm ca.key
 sudo rm ca.crt
echo
echo "Step 2 - Dlete Server Certificate and X509 file from local directory"
echo
 sudo rm ${fqdn}.key
 sudo rm ${fqdn}.csr
 sudo rm v3.ext
 sudo rm ${fqdn}.crt
echo
echo "Step 3 - Delete the certificates for Harbor from /data/cert"
echo
 sudo rm /data/cert/${fqdn}.crt
 sudo rm /data/cert/${fqdn}.key 
echo
echo "Step 4 - Delete the certificates for Docker from local directory and /etc/docker/certs.d/${fqdn}"
echo
 sudo rm ${fqdn}.cert
 sudo rm /etc/docker/certs.d/${fqdn}/${fqdn}.cert 
 sudo rm /etc/docker/certs.d/${fqdn}/${fqdn}.key 
 sudo rm /etc/docker/certs.d/${fqdn}/ca.crt
echo
echo "Step 4 -  Restart Docker"
echo
 sudo systemctl restart docker
echo

