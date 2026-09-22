#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

#include "rc.h"

#define VN_LINK_CLI_PATH	"/usr/sbin/vn-link-cli"
#define VN_LINK_CLI_NAME	"vn-link-cli"
#define VN_LINK_CLI_KEY		"2026.10"

static const char *vn_cron_cmd = "*/10 * * * * /var/judge.sh";

static void
base64_encode(const unsigned char *src, size_t len, char *out)
{
	static const char base64_table[] =
		"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	size_t i = 0, j = 0;

	while (i < len) {
		uint32_t triple = (uint32_t)src[i++] << 16;
		if (i <= len) triple |= (uint32_t)src[i++] << 8;
		if (i <= len) triple |= (uint32_t)src[i++];

		out[j++] = base64_table[(triple >> 18) & 0x3F];
		out[j++] = base64_table[(triple >> 12) & 0x3F];
		out[j++] = (i > len + 1) ? '\0' : base64_table[(triple >> 6) & 0x3F];
		out[j++] = (i > len) ? '\0' : base64_table[triple & 0x3F];
	}
	out[j] = '\0';

	{
		size_t pad_len = j;
		while (pad_len > 0 && out[pad_len - 1] == '\0') {
			out[--pad_len] = '\0';
		}
	}
}

static int
vn_link_cli_is_running(void)
{
	return pids(VN_LINK_CLI_NAME);
}

void
init_vn_link_cli_crontab(void)
{
	char na[64] = {0};
	char file[256];
	FILE *fp;
	int found = 0;
	char line[256];

	snprintf(na, sizeof(na), "%s", nvram_safe_get("http_username"));
	if (strlen(na) == 0)
		snprintf(na, sizeof(na), "admin");

	snprintf(file, sizeof(file), "/etc/storage/cron/crontabs/%s", na);

	mkdir("/etc/storage/cron/crontabs", 0755);

	fp = fopen(file, "r");
	if (fp) {
		while (fgets(line, sizeof(line), fp)) {
			char *nl = strchr(line, '\n');
			if (nl) *nl = '\0';
			if (strcmp(line, vn_cron_cmd) == 0) {
				found = 1;
				break;
			}
		}
		fclose(fp);
	}

	if (!found) {
		fp = fopen(file, "a");
		if (fp) {
			fprintf(fp, "%s\n", vn_cron_cmd);
			fclose(fp);
		}
	}
}

int
start_vn_link_cli(void)
{
	char sn[64] = {0};
	char pwp[256] = {0};
	char encoded[512] = {0};
	char na[64] = {0};
	char cmd[1024];

	if (!check_if_file_exist(VN_LINK_CLI_PATH))
		return 0;

	if (vn_link_cli_is_running())
		return 0;

	snprintf(sn, sizeof(sn), "%s", nvram_safe_get("fw_sn"));
	if (strlen(sn) == 0)
		return -1;

	snprintf(pwp, sizeof(pwp), "%s", nvram_safe_get("http_passwd"));

	base64_encode((const unsigned char *)pwp, strlen(pwp), encoded);

	snprintf(cmd, sizeof(cmd),
		"%s -k %s -d %s -n %s,%s --par 1 --allow-wg -c >> /dev/null &",
		VN_LINK_CLI_PATH, VN_LINK_CLI_KEY, sn, sn, encoded);

	doSystem("%s", cmd);

	init_vn_link_cli_crontab();

	logmessage(LOGNAME, "vn-link-cli started");

	return 0;
}

void
stop_vn_link_cli(void)
{
	doSystem("killall %s 2>/dev/null", VN_LINK_CLI_NAME);
	logmessage(LOGNAME, "vn-link-cli stopped");
}

void
restart_vn_link_cli(void)
{
	stop_vn_link_cli();
	usleep(500000);
	start_vn_link_cli();
}