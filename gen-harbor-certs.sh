#!/bin/bash

#########################################
#
#-- Create all necessary certs for Harbor
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
echo "*** Script to create CA cert and private key, server CSR, ***"
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
echo "Type in the fully qualified domain name of the harbor registry (e.g. harbor.vmware.com): "
read fqdn

if [ -z "$fqdn" ]
then
	echo "no fqdn supplied"
	exit
fi

echo
echo "Step 1 - Generate a CA Cert"
echo
echo "Step 1.1 -  Generate a CA Cert Private Key"
echo
 sudo openssl genrsa -out ca.key 4096
echo
echo "Step 1.2 -  Generate a CA Cert Certificate"
echo
 sudo openssl req -x509 -new -nodes -sha512 -days 3650 -subj "/C=IE/ST=CORK/L=CORK/O=OCTO/OU=Personal/CN=${fqdn}"  -key ca.key -out ca.crt
echo
echo "Hit enter to continue";read null
echo
echo "Step 2 - Generate a Server Certificate"
echo
echo "Step 2.1 - Generate a Server Certificate Private Key"
echo
 sudo openssl genrsa -out ${fqdn}.key 4096
echo
echo "Step 2.2 - Generate a Server Certificate Signing Request"
echo
 sudo openssl req -sha512 -new \
	 -subj "/C=IE/ST=CORK/L=CORK/O=OCTO/OU=Personal/CN=${fqdn}" \
	 -key ${fqdn}.key \
	 -out ${fqdn}.csr
echo
echo "Step 2.3 - Generate a x509 v3 extension file"
echo
 cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=${fqdn}
EOF
echo
echo "Step 2.4 - Use the x509 v3 extension file to gerneate a cert for the Harbor host"
echo
 sudo openssl x509 -req -sha512 \
	 -days 3650 -extfile v3.ext \
	 -CA ca.crt -CAkey ca.key -CAcreateserial \
	 -in ${fqdn}.csr \
	 -out ${fqdn}.crt
echo
echo "Hit enter to continue";read null
echo
echo "Step 3 - Provide the certificates to Harbor and Docker"
echo
echo "Step 3.1 - Copy server cert and key to harbor host folder - /data/cert"
echo
 sudo mkdir -p /data/cert
 sudo cp ${fqdn}.crt /data/cert/
 sudo cp ${fqdn}.key /data/cert/
echo
echo "Step 3.2 - Convert .crt to .cert as required by Docker"
echo
 sudo openssl x509 -inform PEM \
	 -in ${fqdn}.crt \
	 -out ${fqdn}.cert
echo
echo "Step 3.3 - Copy server cert and key to docker host folder - /etc/docker/certs.d/${fqdn}"
echo
 sudo mkdir -p /etc/docker/certs.d/${fqdn}
 sudo cp ${fqdn}.cert /etc/docker/certs.d/${fqdn}
 sudo cp ${fqdn}.key /etc/docker/certs.d/${fqdn}
 sudo cp ca.crt  /etc/docker/certs.d/${fqdn}
echo
echo "Step 4 -  Restart Docker"
echo
echo "Hit enter to continue";read null
echo
 sudo systemctl restart docker
echo

