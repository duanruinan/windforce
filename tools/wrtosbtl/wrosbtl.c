/*****************************************************************************
 * File:		wrtosbtl.c
 * Description:		Write os bootloader image to disk image.
 * Author:		Ruinan Duan <duanruinan@zoho.com>
 * Modify:		09/02/2019 10:42:33 		Created
 *****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

int write_osbtl(FILE *fp_osbtl, FILE *fp_disk, unsigned long offset)
{
	unsigned char *buf;

	if (fp_osbtl == NULL) {
		fprintf(stderr, "fp_osbtl == NULL !");
		return -1;
	}
	if (fp_disk == NULL) {
		fprintf(stderr, "fp_disk == NULL !");
		return -1;
	}
	buf = (unsigned char *)malloc(512 * sizeof(char));
	if (buf == NULL) {
		fprintf(stderr, "cannot alloc memory for osbtl buffer\n");
		return -1;
	}
	memset(buf, 0, 512);
	if (fread(buf, 512, 1, fp_osbtl) != 1) {
		fprintf(stderr, "read osbtl failed. %s\n", strerror(errno));
		free(buf);
		return -1;
	}
	if (fseek(fp_disk, offset, SEEK_SET) < 0) {
		fprintf(stderr, "fseek failed. %s\n", strerror(errno));
		free(buf);
		return -1;
	}
	if (fwrite(buf, 512, 1, fp_disk) != 1) {
		fprintf(stderr, "write osbtl failed. %s\n", strerror(errno));
		free(buf);
		return -1;
	}
	free(buf);
	return 0;
}

struct pte {
	unsigned char attr;
	unsigned char chs_start[3];
	unsigned char type;
	unsigned char chs_end[3];
	unsigned int lba_start;
	unsigned int count_sectors;
};

#define PART_TYPE	0xC8

int check_boot_part(FILE *fp, unsigned int *offs)
{
	unsigned char *buf;
	struct pte *p;
	unsigned int addr = 0x1BE;
	int i;

	if (fseek(fp, 0, SEEK_SET) < 0) {
		fprintf(stderr, "fseek failed. %s\n", strerror(errno));
		return -1;
	}
	
	buf = (unsigned char *)malloc(512);
	if (!buf) {
		fprintf(stderr, "no mem.\n");
		return -1;
	}
	memset(buf, 0, 512);
	if (fread(buf, 512, 1, fp) != 1) {
		fprintf(stderr, "failed to read %s\n", strerror(errno));
		free(buf);
		return -1;
	}
	for (i = 0; i < 4; i++) {
		p = (struct pte *)(&buf[addr]);
		addr += 0x10;
		printf("Part[%d]\n", i);
		printf("\tAttribute: %02X\n", p->attr);
		printf("\tType: %02X\n", p->type);
		printf("\tLBA start: %u\n", p->lba_start);
		printf("\tCount of sectors: %u\n", p->count_sectors);
		if (p->type == PART_TYPE) {
			printf("Find a wf boot partition\n");
			*offs = p->lba_start;
			return 0;
		} else {
			continue;
		}
	}
	return -1;
}

int main(int argc, char **argv)
{
	FILE *fp_osbtl, *fp_disk;
	unsigned int lba;
	unsigned long offs;

	if (argc < 3) {
		printf("\nUsage writeosbtl OSBTLBinName DiskImageName\n");
		return -1;
	}
	
	fp_osbtl = fopen(argv[1], "rb");
	if (fp_osbtl == NULL) {
		fprintf(stderr, "Open %s failed. %s\n", argv[1],
			strerror(errno));
		return -1;
	}

	fp_disk = fopen(argv[2], "rb+");
	if (fp_disk == NULL) {
		fprintf(stderr, "Open %s failed. %s\n", argv[2],
			strerror(errno));
		fclose(fp_osbtl);
		return -1;
	}

	if (check_boot_part(fp_disk, &lba) < 0) {
		fclose(fp_osbtl);
		fclose(fp_disk);
		return -1;
	}

	offs = lba * 512;

	printf("offset of os bootloader is: %lu\n", offs);

	if (write_osbtl(fp_osbtl, fp_disk, offs) < 0) {
		fprintf(stderr, "Writing OSBTL to disk image failed.\n");
		fclose(fp_osbtl);
		fclose(fp_disk);
		return -1;
	} else {
		printf("Writing OSBTL to disk image successfully.\n");
		fclose(fp_osbtl);
		fclose(fp_disk);
		return 0;
	}
}


