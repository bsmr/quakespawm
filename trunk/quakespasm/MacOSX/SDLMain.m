/*   SDLMain.m - main entry point for our Cocoa-ized SDL app
       Initial Version: Darrell Walisser <dwaliss1@purdue.edu>
       Non-NIB-Code & other changes: Max Horn <max@quendi.de>

    Feel free to customize this file to suit your needs
*/

#if defined(SDL_FRAMEWORK) || defined(NO_SDL_CONFIG)
#import <SDL/SDL.h>
#else
#import "SDL.h"
#endif
#import "SDLMain.h"
#import <sys/param.h> /* for MAXPATHLEN */
#import <unistd.h>
#import "SDLApplication.h"

int    gArgc;
char  **gArgv;
BOOL   gFinderLaunch;
BOOL   gCalledAppMainline = FALSE;

/* The main class of the application, the application's delegate */
@implementation SDLMain

/* Set the working directory to the .app's parent directory */
- (void) setupWorkingDirectory:(BOOL)shouldChdir
{
    if (shouldChdir)
    {
        char parentdir[MAXPATHLEN];
		CFURLRef url = CFBundleCopyBundleURL(CFBundleGetMainBundle());
		CFURLRef url2 = CFURLCreateCopyDeletingLastPathComponent(0, url);
		if (CFURLGetFileSystemRepresentation(url2, true, (UInt8 *)parentdir, MAXPATHLEN)) {
	        assert ( chdir (parentdir) == 0 );   /* chdir to the binary app's parent */
		}
		CFRelease(url);
		CFRelease(url2);
	}

}

/* Called when the internal event loop has just started running */
- (void) applicationDidFinishLaunching: (NSNotification *) note
{
    int status;

    /* Set the working directory to the .app's parent directory */
    [self setupWorkingDirectory:gFinderLaunch];

    /* Hand off to main application code */
    gCalledAppMainline = TRUE;
    status = SDL_main (gArgc, gArgv);

    /* We're done, thank you for playing */
    exit(status);
}
@end


#ifdef main
#  undef main
#endif


static int IsRootCwd()
{
    char buf[MAXPATHLEN];
    char *cwd = getcwd(buf, sizeof (buf));
    return (cwd && (strcmp(cwd, "/") == 0));
}

static int IsTenPointNineOrLater()
{
    /* Gestalt() is deprecated in 10.8, but I don't care. Stop using SDL 1.2. */
    SInt32 major, minor;
    Gestalt(gestaltSystemVersionMajor, &major);
    Gestalt(gestaltSystemVersionMinor, &minor);
    return ( ((major << 16) | minor) >= ((10 << 16) | 9) );
}

static int IsFinderLaunch(const int argc, char **argv)
{
    const int bIsNewerOS = IsTenPointNineOrLater();
    /* -psn_XXX is passed if we are launched from Finder in 10.8 and earlier */
    if ( (!bIsNewerOS) && (argc >= 2) && (strncmp(argv[1], "-psn", 4) == 0) ) {
        return 1;
    } else if ((bIsNewerOS) && (argc == 1) && IsRootCwd()) {
        /* we might still be launched from the Finder; on 10.9+, you might not
        get the -psn command line anymore. Check version, if there's no
        command line, and if our current working directory is "/". */
        return 1;
    }
    return 0;  /* not a Finder launch. */
}

/* Main entry point to executable - should *not* be SDL_main! */
int main (int argc, char **argv)
{
    /* Copy the arguments into a global variable */
    if (IsFinderLaunch(argc, argv)) {
        gArgv = (char **) SDL_malloc(sizeof (char *) * 2);
        gArgv[0] = argv[0];
        gArgv[1] = NULL;
        gArgc = 1;
        gFinderLaunch = YES;
    } else {
        int i;
        gArgc = argc;
        gArgv = (char **) SDL_malloc(sizeof (char *) * (argc+1));
        for (i = 0; i <= argc; i++)
            gArgv[i] = argv[i];
        gFinderLaunch = NO;
    }

    NSApplicationMain (argc, (const char**) argv);
    return 0;
}
