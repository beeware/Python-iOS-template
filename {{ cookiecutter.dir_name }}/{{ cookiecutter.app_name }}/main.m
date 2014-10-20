//
//  main.m
//  A main module for starting Python projects under iOS.
//
//  Copyright (c) 2014 Russell Keith-Magee.
//  Released under the terms of the BSD license.
//  Based on an intial file provided as part of the Kivy project
//  Copyright (c) 2014 Russell Keith-Magee.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <Python/Python.h>
#include <dlfcn.h>

int main(int argc, char *argv[]) {
    int ret = 0;

    @autoreleasepool {

#if TARGET_IPHONE_SIMULATOR
        putenv("TARGET_IPHONE_SIMULATOR=1");
#else
        putenv("TARGET_IPHONE=1");
#endif

        NSString * resourcePath = [[NSBundle mainBundle] resourcePath];

        // Special environment to prefer .pyo, and don't write bytecode if .py are found
        // because the process will not have write attribute on the device.
        putenv("PYTHONOPTIMIZE=2");
        putenv("PYTHONDONTWRITEBYTECODE=1");
        putenv("PYTHONNOUSERSITE=1");

        NSString *python_path = [NSString stringWithFormat:@"PYTHONPATH=%@/app:%@/app_packages", resourcePath, resourcePath, nil];
        putenv((char *)[python_path UTF8String]);
        // putenv("PYTHONVERBOSE=1");

        NSLog(@"PythonHome is: %s", [resourcePath UTF8String]);
        Py_SetPythonHome((char *)[resourcePath UTF8String]);

        NSLog(@"Initializing Python runtime");
        Py_Initialize();
        PySys_SetArgv(argc, argv);

        // If other modules are using thread, we need to initialize them before.
        PyEval_InitThreads();

        // Search and start main.py
        const char * prog = [[[NSBundle mainBundle] pathForResource:@"app/{{ cookiecutter.app_name }}/main" ofType:@"py"] cStringUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"Running %s", prog);
        FILE* fd = fopen(prog, "r");
        if (fd == NULL)
        {
            ret = 1;
            NSLog(@"Unable to open main.py, abort.");
        }
        else
        {
            ret = PyRun_SimpleFileEx(fd, prog, 1);
            if (ret != 0)
            {
                NSLog(@"Application quit abnormally!");
            }
        }

        @try
        {
            // Start the Python app
            UIApplicationMain(0, NULL, NULL, @"PythonAppDelegate");
        }
        @catch (NSException *exception)
        {
            NSLog(@"Error running Python application: %@", exception.reason);
        }

        Py_Finalize();
        NSLog(@"Leaving");
    }

    exit(ret);
    return ret;
}
