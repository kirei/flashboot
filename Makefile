# Adapted from distrib/i386/common/Makefile.inc:
#	$OpenBSD: Makefile.inc,v 1.8 2002/09/23 18:31:03 markus Exp $

# NB. the disktab specified in ${DISKPROTO}, the ramdisk size specified in 
#     ${NBLKS} and the MINIROOTSIZE in the kernel config (${KERNEL}) must 
#     *ALL* match

ALL_KCONF=	WRAP12 COMMELL-LE564 SOEKRIS4501 SOEKRIS4801 SOEKRIS5501 GENERIC-RD

KCONF=		COMMELL-LE564
TTYSPEED=	19200

# WRAP has an even sillier default console speed than Soekris :)
.if ${KCONF} == "WRAP12"
TTYSPEED=	38400
.endif

# Change the default conspeed of Generic to 9600
.if ${KCONF} == "GENERIC-RD"
TTYSPEED=	9600
.endif

.include <bsd.own.mk>

# Build options
#NBLKS=		16384		# disktab.8mb
#NBLKS=		19456		# disktab.9.5mb
#NBLKS=		20480		# disktab.10mb
#NBLKS=		24576		# disktab.12mb
#NBLKS=		30720		# disktab.15mb
NBLKS=		98304		# disktab.48mb
NEWFSARGS=	-m 0 -o space
KOPTS=		#-Os

TERMTYPES=	dumb unknown vt100 vt100-nav vt220 xterm xterm-new \
		xterm-xfree86 cygwin gnome vt102 ansi screen

.PATH:		${.CURDIR}
TOP=		${.CURDIR}

# Local config files
KERNEL=		${.CURDIR}/${KCONF}
LIST=		${.CURDIR}/list
EXTRACONF=	${.CURDIR}/conf
#DISKPROTO=	${.CURDIR}/disktabs/disktab.8mb
#DISKPROTO=	${.CURDIR}/disktabs/disktab.9.5mb
#DISKPROTO=	${.CURDIR}/disktabs/disktab.10mb
#DISKPROTO=	${.CURDIR}/disktabs/disktab.12mb
#DISKPROTO=	${.CURDIR}/disktabs/disktab.15mb
DISKPROTO=      ${.CURDIR}/disktabs/disktab.48mb
MTREE=		${DESTDIR}/etc/mtree/4.4BSD.dist
MTREE_CUST=	${.CURDIR}/mtree.conf

# Paths to various things, probably don't need to touch
MOUNT_POINT=	/mnt
SRCDIR?=	/usr/src
KSRC=		${SRCDIR}/sys
VND=		vnd0
DESTDIR?=	/

# Shouldn't need to touch these
IMAGE=		mr.fs
CBIN=		instbin
CRUNCHCONF=	${CBIN}.conf
UTILS=		${.CURDIR}/tools
VND_DEV=	/dev/${VND}a
VND_RDEV=	/dev/r${VND}a
PID!=		echo $$$$
REALIMAGE!=	echo /var/tmp/image.${PID}

all:	bsd.gz
	ls -l bsd.rd bsd.gz

everything:
	set -xe ; for kconf in ${ALL_KCONF} ; do \
		cd ${.CURDIR} && make cleandir ; \
		cd ${.CURDIR} && make KCONF=$$kconf ; \
		mv ${.OBJDIR}/bsd.gz ${.OBJDIR}/bsd.$$kconf ; \
	done

bsd.gz: bsd.rd
	gzip -c9 bsd.rd > bsd.gz

bsd.rd:	termdefs bsd ${IMAGE} rdsetroot
	cp bsd bsd.rd
	${.OBJDIR}/rdsetroot bsd.rd < ${IMAGE}

bsd: ${KCONF}/bsd
	cp ${KCONF}/bsd .

${KCONF}/bsd: ${KERNEL}
	-test -f ${KCONF} && (echo ""; make clean obj; echo "Missing obj/ dir (created). Now rerun 'make'."; exit 1)
	test -d ${KCONF} || mkdir ${KCONF}
	cd ${KCONF} && config -s ${KSRC} -b . ${KERNEL}
	cd ${KCONF} && make clean && make depend && COPTS="${KOPTS}" make
	strip -g -X -x ${KCONF}/bsd
	cp ${KCONF}/bsd .

${IMAGE}: ${CBIN} rd_setup do_files zerofill rd_teardown

rd_setup: ${CBIN}
	dd if=/dev/zero of=${REALIMAGE} bs=512 count=${NBLKS}
	${SUDO} vnconfig -v -c ${VND} ${REALIMAGE}
	${SUDO} disklabel -R ${VND} ${DISKPROTO}
	${SUDO} newfs ${NEWFSARGS} ${VND_RDEV}
	${SUDO} fsck ${VND_RDEV}
	${SUDO} mount ${VND_DEV} ${MOUNT_POINT}

rd_teardown:
	@df -ki ${MOUNT_POINT}
	-${SUDO} umount ${MOUNT_POINT}
	-${SUDO} vnconfig -u ${VND}
	${SUDO} cp ${REALIMAGE} ${IMAGE}
	${SUDO} rm ${REALIMAGE}

rdsetroot:	${UTILS}/elfrdsetroot.c
	${HOSTCC} -DDEBUG -o rdsetroot ${UTILS}/elfrdsetroot.c

unconfig:
	-${SUDO} umount -f ${MOUNT_POINT}
	-${SUDO} vnconfig -u ${VND}

.PRECIOUS:	${IMAGE}

${CBIN}.mk ${CBIN}.cache ${CBIN}.c: ${CRUNCHCONF}
	crunchgen -E -D ${BSDSRCDIR} -L ${DESTDIR}/usr/lib \
	-c ${CBIN}.c -e ${CBIN} -m ${CBIN}.mk ${CRUNCHCONF}

${CBIN}: ${CBIN}.mk ${CBIN}.cache ${CBIN}.c
	make -f ${CBIN}.mk all

${CRUNCHCONF}: ${LIST}
	awk -f ${UTILS}/makeconf.awk CBIN=${CBIN} ${LIST} > ${CRUNCHCONF}

do_files:
	-${SUDO} mtree -def ${MTREE_CUST} -p ${MOUNT_POINT}/ -u
	-${SUDO} mtree -def ${MTREE} -p ${MOUNT_POINT}/ -u
	${SUDO} env \
	    TOPDIR=${TOP} CURDIR=${.CURDIR} OBJDIR=${.OBJDIR} SRCDIR=${SRCDIR} \
	    TARGDIR=${MOUNT_POINT} UTILS=${UTILS} DESTDIR=${DESTDIR} \
	    TTYSPEED=${TTYSPEED} \
	    sh ${UTILS}/runlist.sh ${LIST}
	${SUDO} rm -f ${MOUNT_POINT}/${CBIN}

# Zero out unused space on virtual disk to help compression
zerofill:
	-${SUDO} dd if=/dev/zero of=${MOUNT_POINT}/zero.temp >/dev/null 2>&1
	-${SUDO} rm -f ${MOUNT_POINT}/zero.temp

# targets to build minimal termcap/terminfo databases
terminfo.mini:
	-rm -f terminfo.mini
	for termtype in ${TERMTYPES} ; do \
		infocmp $$termtype >> terminfo.mini ;\
	done

termcap.mini: terminfo.mini
	infotocap terminfo.mini > termcap.mini

terminfo.db: terminfo.mini
	cap_mkdb -i -f terminfo terminfo.mini

termcap.db: termcap.mini
	cap_mkdb -f termcap termcap.mini

termdefs: termcap.db terminfo.db
	rm -rf termdefs
	mkdir -p termdefs/usr/share/misc
	install -m 0444 termcap.mini termdefs/usr/share/misc/termcap
	install -m 0444 termcap.db termdefs/usr/share/misc/termcap.db
	install -m 0444 terminfo.db termdefs/usr/share/misc/terminfo.db

halfclean:
	/bin/rm -f core ${IMAGE} ${CBIN} ${CBIN}.mk ${CBIN}*.cache \
	    *.o *.lo *.c bsd bsd.rd bsd.gz bsd.strip rdsetroot ${CRUNCHCONF} \
	    *.tar *.tgz
	/bin/rm -rf term*

clean cleandir: halfclean
	-test -d ${KCONF} && /bin/rm -rf ${KCONF}

.include <bsd.obj.mk>
.include <bsd.subdir.mk>
