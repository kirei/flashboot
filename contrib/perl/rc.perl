if [ -e /flash/perl/perl_modules.tgz ]; then

# Create mount if needed
 if [ X"${usrlocal_size}" != X"NO" ] && [ ! -d /usr/local ] ; then
	echo "Creating /usr/local filesystem..."
	mkdir -p /usr/local
	if ! mount_mfs -s ${usrlocal_size} swap /usr/local ; then
		echo "Mount /usr/local failed"
		exit 1
	fi

 fi

# Create perl dir
 if [ ! -d /usr/local/perl ] ; then
 	mkdir /usr/local/perl
 fi 

# Unpack into perldir
 if [ -d /usr/local/perl ] ; then
	cd /usr/local/perl
	for pkg in /flash/perl/*.tgz ; do
		if [ -r $pkg ]; then
			echo -n "Unpacking package ${pkg} from flash... "
			tar zxf ${pkg} 2>/dev/null
			echo "done"
		fi
	done
 fi

# Create symbolic link for perl-libs
 if [ ! -d /usr/libdata ]; then
	ln -s /usr/local/perl/usr/libdata /usr/libdata
 fi
fi
