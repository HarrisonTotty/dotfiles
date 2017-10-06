#include <stdio.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>

#define LEFT    0
#define RIGHT   0
#define TOP     0
#define BOTTOM  16


// compile with:
// gcc -L/usr/X11R6/lib -lX11 -o make-strut make-strut.c
int main(int argc, char **argv)
{
    Display         *dpy;
    Window          win;
    XEvent          event;
    unsigned long   strut[4];
    XWMHints        xwmh = { (InputHint|StateHint), False, IconicState,
                             0, 0, 0, 0, 0, 0, };

    if ((dpy = XOpenDisplay(NULL)) == NULL) {
        fprintf(stderr, "%s: can't open %s\en", argv[0], XDisplayName(NULL));
        return 1;
    }

    win = XCreateSimpleWindow(dpy, DefaultRootWindow(dpy), 0, 0, 1, 1, 0, 0, 0);

    XSetWMHints(dpy, win, &xwmh);
    XMapWindow(dpy, win);

    strut[0] = LEFT;
    strut[1] = RIGHT;
    strut[2] = TOP;
    strut[3] = BOTTOM;

    XChangeProperty(dpy, win, XInternAtom(dpy, "_NET_WM_STRUT", False),
        XA_CARDINAL, 32, PropModeReplace, (unsigned char *) strut, 4);

    while (1) {
        XNextEvent(dpy, &event);
    }
}
 
