/*
 * qwebengine-std-function.h
 *
 * C++ helper to bridge CFFI callbacks to Qt6's std::function<void(const QVariant&)>
 * for QWebEnginePage::runJavaScript callback parameters.
 *
 * The issue: Qt6 expects a std::function<void(const QVariant&)> callback,
 * but CommonQt cannot automatically marshal a Lisp/CFFI callback into that C++ type.
 *
 * Solution: provide extern "C" helper functions that:
 * 1. Accept a C function pointer and user_data
 * 2. Create a std::function object that captures them
 * 3. Return a pointer to a wrapper that Qt can call
 * 4. Provide cleanup to free the wrapper after use
 */

#ifndef QWEBENGINE_STD_FUNCTION_H
#define QWEBENGINE_STD_FUNCTION_H

#include "commonqt.h"
#include <functional>
#include <QVariant>

#ifdef __cplusplus
extern "C" {
#endif

    /*
     * Create a std::function<void(const QVariant&)> wrapper.
     *
     * Args:
     *   c_callback: C function pointer void (*)(const QVariant*, void*)
     *   user_data: opaque pointer passed to c_callback as second argument
     *
     * Returns: opaque pointer to a std::function object (heap-allocated)
     *
     * The returned pointer must be freed with destroy_std_function_wrapper() after use.
     */
    EXPORT void *create_std_function_wrapper(void (*c_callback)(const QVariant *, void *),
                                             void *user_data);

    /*
     * Free a std::function wrapper created by create_std_function_wrapper().
     *
     * Args:
     *   wrapper_ptr: opaque pointer returned from create_std_function_wrapper()
     */
    EXPORT void destroy_std_function_wrapper(void *wrapper_ptr);

    /*
     * Get the std::function<void(const QVariant&)>* pointer from a wrapper.
     *
     * Used internally by the marshalling code to pass to Qt.
     */
    EXPORT std::function<void(const QVariant &)> *get_std_function_ptr(void *wrapper_ptr);

#ifdef __cplusplus
}
#endif

#endif /* QWEBENGINE_STD_FUNCTION_H */
