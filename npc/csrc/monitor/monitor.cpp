#include <memory.h> 
#include <getopt.h>

void init_log(const char *log_file); 
void init_mem();
void init_cpu();

static void welcome() {
	Log("Trace: %s", MUXDEF(CONFIG_TRACE, ANSI_FMT("ON", ANSI_FG_GREEN), ANSI_FMT("OFF", ANSI_FG_RED)));
	IFDEF(CONFIG_TRACE, Log("If trace is enabled, a log file will be generated "
				"to record the trace. This may lead to a large log file. "
				"If it is not necessary, you can disable it in menuconfig"));
	Log("Build time: %s, %s", __TIME__, __DATE__);
	printf("Welcome to NPC!\n");
	printf("For help, type \"help\"\n");
}

static char *log_file = NULL;
static char *img_file = NULL;

static long load_img() {
	if (img_file == NULL) {
		printf("No image is given. Use the default build-in image.");
		return 4096; // built-in image size
	}
	long result =0;
	result = load_mem(img_file);
	return result;
}

static int parse_args(int argc, char *argv[]) {
	const struct option table[] = {
		//{"batch"    , no_argument      , NULL, 'b'},
		{"log"      , required_argument, NULL, 'l'},
		{"help"     , no_argument      , NULL, 'h'},
		{0          , 0                , NULL,  0 },
	};
	int o;
	while ( (o = getopt_long(argc, argv, "-hl:", table, NULL)) != -1) {
		switch (o) {
			 //case 'b': sdb_set_batch_mode(); break;
			 case 'l': log_file = optarg; break;
			 case 1: img_file = optarg; return 0;
			 default:
				 printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
				 printf("\t-b,--batch              run with batch mode\n");
				 printf("\t-l,--log=FILE           output log to FILE\n");
				 printf("\n");
				 exit(0);
		}
	}
	return 0;
}

void init_monitor(int argc, char *argv[]) {

	/* Parse arguments. */
	parse_args(argc, argv);

	/* Open the log file. */
	init_log(log_file);

	/* Initialize memory. */
	init_mem();

	/* Initialize memory. */
	init_cpu();

	/* Load the image to memory. This will overwrite the built-in image. */
	long img_size = load_img();

	/* Display welcome message. */
	welcome();
}

