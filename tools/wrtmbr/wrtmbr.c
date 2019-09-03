/*****************************************************************************
 * File:		wrtmbr.c
 * Description:		Write mbr image to disk image.
 * 			Partition table is skipped.
 * Author:		Ruinan Duan <duanruinan@zoho.com>
 * Modify:		09/02/2019 10:42:33 		Created
 *****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

int write_mbr(FILE *fp_mbr, FILE *fp_disk)
{
	unsigned char *buf;

	if (fp_mbr == NULL) {
		fprintf(stderr, "fp_mbr == NULL !");
		return -1;
	}
	if (fp_disk == NULL) {
		fprintf(stderr, "fp_disk == NULL !");
		return -1;
	}
	buf = (unsigned char *)malloc(512 * sizeof(char));
	if (buf == NULL) {
		fprintf(stderr, "cannot alloc memory for mbr buffer\n");
		return -1;
	}
	memset(buf, 0, 512);
	if (fread(buf, 512, 1, fp_mbr) != 1) {
		fprintf(stderr, "read mbr failed. %s\n", strerror(errno));
		free(buf);
		return -1;
	}
	if (fseek(fp_disk, 0, SEEK_SET) < 0) {
		fprintf(stderr, "fseek failed. %s\n", strerror(errno));
		free(buf);
		return -1;
	}
	/* skip partition table */
	if (fwrite(buf, 440, 1, fp_disk) != 1) {
		fprintf(stderr, "write mbr failed. %s\n", strerror(errno));
		free(buf);
		return -1;
	}
	if (fseek(fp_disk, 512 - 2, SEEK_SET) < 0) {
		fprintf(stderr, "fseek failed. %s\n", strerror(errno));
		free(buf);
		return -1;
	}
	if (fwrite(buf + 510, 2, 1, fp_disk) != 1) {
		fprintf(stderr, "write mbr failed. %s\n", strerror(errno));
		free(buf);
		return -1;
	}
	free(buf);
	return 0;
}

int main(int argc, char **argv)
{
	FILE *fp_mbr, *fp_disk;

	if (argc < 3) {
		printf("\nUsage writembr MBRBinName DiskImageName\n");
		return -1;
	}
	
	fp_mbr = fopen(argv[1], "rb");
	if (fp_mbr == NULL) {
		fprintf(stderr, "Open %s failed. %s\n", argv[1],
			strerror(errno));
		return -1;
	}

	fp_disk = fopen(argv[2], "rb+");
	if (fp_disk == NULL) {
		fprintf(stderr, "Open %s failed. %s\n", argv[2],
			strerror(errno));
		fclose(fp_mbr);
		return -1;
	}

	if (write_mbr(fp_mbr, fp_disk) < 0) {
		fprintf(stderr, "Writing MBR to disk image failed.\n");
		fclose(fp_mbr);
		fclose(fp_disk);
		return -1;
	} else {
		printf("Writing MBR to disk image successfully.\n");
		fclose(fp_mbr);
		fclose(fp_disk);
		return 0;
	}
}


