//
//  main.m
//  A main module for starting Python projects under iOS.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <Python.h>
#include <dlfcn.h>


int main(int argc, char *argv[]) {
    int ret = 0;
    unsigned int i;
    NSString *tmp_path;
    NSString *python_home;
    NSString *python_path;
    char *wpython_home;
    const char* nslog_script;
    const char* main_script;
    char** python_argv;

    @autoreleasepool {

        NSString * resourcePath = [[NSBundle mainBundle] resourcePath];

        // Special environment to avoid writing bytecode because
        // the process will not have write attribute on the device.
        putenv("PYTHONDONTWRITEBYTECODE=1");

        // Set the home for the Python interpreter
        python_home = [NSString stringWithFormat:@"%@/Library/Python", resourcePath, nil];
        NSLog(@"PythonHome is: %@", python_home);
        wpython_home = strdup([python_home UTF8String]);
        Py_SetPythonHome(wpython_home);

        // Set the PYTHONPATH
        python_path = [NSString stringWithFormat:@"PYTHONPATH=%@/Library/Application Support/{{ cookiecutter.bundle }}.{{ cookiecutter.app_name }}/app:%@/Library/Application Support/{{ cookiecutter.bundle }}.{{ cookiecutter.app_name }}/app_packages", resourcePath, resourcePath, nil];
        NSLog(@"PYTHONPATH is: %@", python_path);
        putenv((char *)[python_path UTF8String]);

        // iOS provides a specific directory for temp files.
        tmp_path = [NSString stringWithFormat:@"TMP=%@/tmp", resourcePath, nil];
        putenv((char *)[tmp_path UTF8String]);

        NSLog(@"Initializing Python runtime...");
        Py_Initialize();

        // Set the name of the python NSLog bootstrap script
        nslog_script = [
            [[NSBundle mainBundle] pathForResource:@"Library/Application Support/{{ cookiecutter.bundle }}.{{ cookiecutter.app_name }}/app_packages/nslog"
                                            ofType:@"py"] cStringUsingEncoding:NSUTF8StringEncoding];

        if (nslog_script == NULL) {
            NSLog(@"Unable to locate NSLog bootstrap script.");
            exit(-2);
        }

        // Set the name of the main script
        main_script = [
            [[NSBundle mainBundle] pathForResource:@"Library/Application Support/{{ cookiecutter.bundle }}.{{ cookiecutter.app_name }}/app/{{ cookiecutter.app_name }}/__main__"
                                            ofType:@"py"] cStringUsingEncoding:NSUTF8StringEncoding];

        if (main_script == NULL) {
            NSLog(@"Unable to locate {{ cookiecutter.app_name }} main module file.");
            exit(-1);
        }

        // Construct argv for the interpreter
        python_argv = PyMem_Malloc(sizeof(char *) * argc);

        python_argv[0] = strdup(main_script);
        for (i = 1; i < argc; i++) {
            python_argv[i] = argv[i];
        }

        PySys_SetArgv(argc, python_argv);

        // If other modules are using threads, we need to initialize them.
        PyEval_InitThreads();

        @try {
            NSLog(@"Installing Python NSLog handler...");
            FILE* fd = fopen(nslog_script, "r");
            if (fd == NULL) {
                ret = 1;
                NSLog(@"Unable to open nslog.py; abort.");
            } else {
                ret = PyRun_SimpleFileEx(fd, nslog_script, 1);
                fclose(fd);
                if (ret != 0) {
                    NSLog(@"Unable to install Python NSLog handler; abort.");
                } else {
                    // Start the main.py script
                    NSLog(@"Running '%s'...", main_script);

                    fd = fopen(main_script, "r");
                    if (fd == NULL) {
                        ret = 1;
                        NSLog(@"Unable to open '%s'; abort.", main_script);
                    } else {
                        ret = PyRun_SimpleFileEx(fd, main_script, 1);
                        fclose(fd);
                        if (ret != 0) {
                            NSLog(@"Application quit abnormally!");
                        } else {
                            // In a normal iOS application, the following line is what
                            // actually runs the application. It requires that the
                            // Objective-C runtime environment has a class named
                            // "PythonAppDelegate". This project doesn't define
                            // one, because Objective-C bridging isn't something
                            // Python does out of the box. You'll need to use
                            // a library like Rubicon-ObjC [1], Pyobjus [2] or
                            // PyObjC [3] if you want to run an *actual* iOS app.
                            // [1] http://pybee.org/rubicon
                            // [2] http://pyobjus.readthedocs.org/
                            // [3] https://pythonhosted.org/pyobjc/

                            UIApplicationMain(argc, argv, nil, @"PythonAppDelegate");
                        }
                    }
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Python runtime error: %@", [exception reason]);
        }
        @finally {
            Py_Finalize();
        }

        PyMem_Free(wpython_home);
        if (python_argv) {
            for (i = 0; i < argc; i++) {
                PyMem_Free(python_argv[i]);
            }
            PyMem_Free(python_argv);
        }
        NSLog(@"Leaving...");
    }

    exit(ret);
    return ret;
}
