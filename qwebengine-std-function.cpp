/*
 * qwebengine-std-function.cpp
 *
 * Implementation of C++ helpers to bridge CFFI callbacks to std::function
 * for Qt6 QWebEnginePage::runJavaScript.
 */

#include "qwebengine-std-function.h"
#include <memory>

struct StdFunctionWrapper {
    std::function<void(const QVariant&)> func;
    
    StdFunctionWrapper(std::function<void(const QVariant&)> f)
        : func(f) {}
};

EXPORT void* create_std_function_wrapper(void (*c_callback)(const QVariant*, void*),
                                   void* user_data)
{
    if (!c_callback) {
        return nullptr;
    }
    
    // Create a std::function that captures the C callback and user_data
    auto wrapper = new StdFunctionWrapper(
        [c_callback, user_data](const QVariant& result) {
            // Call the C callback, passing the QVariant by pointer
            c_callback(&result, user_data);
        }
    );
    
    return static_cast<void*>(wrapper);
}

EXPORT void destroy_std_function_wrapper(void* wrapper_ptr)
{
    if (wrapper_ptr) {
        delete static_cast<StdFunctionWrapper*>(wrapper_ptr);
    }
}

EXPORT std::function<void(const QVariant&)>* get_std_function_ptr(void* wrapper_ptr)
{
    if (!wrapper_ptr) {
        return nullptr;
    }
    return &(static_cast<StdFunctionWrapper*>(wrapper_ptr)->func);
}
