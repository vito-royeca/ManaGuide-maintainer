package com.managuide.maintainer;

import com.manakit.ManaKit;
import org.apache.commons.io.FileUtils;

import java.io.File;
import java.io.IOException;
import java.net.URL;

public class SetsMaintainer {
    void fetchSetsData() {
        String setsPath = "build/" + ManaKit.Constants.ScryfallDate + "_" + Maintainer.setsFileName;
        File setsFile = new File(setsPath);
        Boolean willFetch = !setsFile.exists();

        if (willFetch) {
            try {
                URL url = new URL("https://api.scryfall.com/sets");
                FileUtils.copyURLToFile(url, setsFile);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }
}
