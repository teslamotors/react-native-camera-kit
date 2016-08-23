package com.wix.RNCameraKit.camera.commands;

import com.facebook.react.bridge.Promise;

public interface Command {
    void execute(Promise promise);
}
