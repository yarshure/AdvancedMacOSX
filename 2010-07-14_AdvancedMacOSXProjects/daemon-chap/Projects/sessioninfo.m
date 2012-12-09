#import <Security/Security.h>
#import <Security/AuthSession.h>

/* compile with
gcc -g -Wall -framework Security -o sessioninfo sessioninfo.m
*/

int main (void) {
    OSStatus error;
    SecuritySessionId session;
    SessionAttributeBits sessionInfo;

    error = SessionGetInfo (callerSecuritySession,
                            &session, &sessionInfo);
    if (error == noErr) {
        printf ("session Id: %d, bits 0x%x\n", 
                (int)session, (int)sessionInfo);
        if (sessionInfo & sessionIsRoot) printf ("  root\n");
        if (sessionInfo
            & sessionHasGraphicAccess) printf ("  graphics\n");
        if (sessionInfo & sessionHasTTY) printf ("  tty\n");
        if (sessionInfo & sessionIsRemote) printf ("  remote\n");
        if (sessionInfo & sessionWasInitialized) printf ("  init\n");
    }

    return EXIT_SUCCESS;

} // main


/*

local:
% ./sessioninfo
session Id: 12248640, bits 0x8030
  graphics
  tty
  init

other user:
% ./sessioninfo
session Id: 574451712, bits 0x8030
  graphics
  tty
  init

ssh session:
% ./sessioninfo
session Id: 567077184, bits 8000

