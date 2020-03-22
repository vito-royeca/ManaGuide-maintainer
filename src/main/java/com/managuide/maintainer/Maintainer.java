package com.managuide.maintainer;

import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.nio.charset.Charset;
import java.util.Date;

import com.manakit.ManaKit;
import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.riversun.promise.Action;
import org.riversun.promise.Func;
import org.riversun.promise.Promise;
import org.json.JSONArray;
import org.json.JSONObject;

public class Maintainer {
    /**
     * Constants
     */
    static final int printMilestone = 1000;
    static final String cardsFileName   = "scryfall-all-cards.json";
    static final String rulingsFileName = "scryfall-rulings.json";
    static final String setsFileName    = "scryfall-sets.json";
    static final String keyruneFileName = "keyrune.html";
    static final String comprehensiveRulesFileName = "MagicCompRules 20200122";
    static final String storeName = "TCGPlayer";

    /**
     * Variables
     */
    private Date dateStart;

    public void checkServerInfo() {
        try {
            String link = "http://192.168.1.182:1993/serverinfo?json=true";

            JSONArray array = new JSONArray(IOUtils.toString(new URL(link), Charset.forName("UTF-8")));
            Boolean willUpdate = false;

            for (Object object : array) {
                JSONObject json = (JSONObject) object;
                String scryfallVersion = json.getString("scryfall_version");
                willUpdate = scryfallVersion != ManaKit.Constants.ScryfallDate.getValue();
            }

            if (willUpdate) {
                updateDatabase();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    void updateDatabase() {
        String localPrefix       = "build/" + ManaKit.Constants.ScryfallDate.getValue() + "_";
        String setsLocalPath     = localPrefix + Maintainer.setsFileName;
        String setsRemotePath    = "https://api.scryfall.com/sets";
        String keyruneLocalPath  = localPrefix + Maintainer.keyruneFileName;
        String keyruneRemotePath = "http://andrewgioia.github.io/Keyrune/cheatsheet.html";
        String cardsLocalPath    = localPrefix + Maintainer.cardsFileName;
        String cardsRemotePath   = "https://archive.scryfall.com/json/"+ cardsFileName;
        String rulingsLocalPath  = localPrefix + Maintainer.rulingsFileName;
        String rulingsRemotePath = "https://archive.scryfall.com/json/" + rulingsFileName;

        Func done = (action, data) -> {
            endActivity();
            action.resolve();
        };

        startActivity();
        Promise.resolve()
            .then(fetchData(setsLocalPath, setsRemotePath))
            .then(fetchData(keyruneLocalPath, keyruneRemotePath))
            .then(fetchData(cardsLocalPath, cardsRemotePath))
            .then(fetchData(rulingsLocalPath, rulingsRemotePath))
            .then(new Promise(done))
            .start();
    }

    /**
     * Utility methods
     */

    Func fetchData(String localPath, String remotePath) {
        return new Func() {
            @Override
            public void run(Action action, Object data) throws Exception {
                File file = new File(localPath);
                Boolean willFetch = !file.exists();

                if (willFetch) {
                    try {
                        URL url = new URL(remotePath);
                        FileUtils.copyURLToFile(url, file);
                        action.resolve();
                    } catch (IOException e) {
                        action.reject();
                    }
                }
            }
        };
    }

    void startActivity() {
        dateStart = new Date();
        System.out.println("Starting on... " + dateStart);
    }

    void endActivity() {
        Date dateEnd = new Date();
        long timeDifference = dateEnd.getTime() - dateStart.getTime();

        System.out.printf("Total Time Elapsed on: %s - %s = %s\n", dateStart, dateEnd, format(timeDifference));
    }

    String format(long interval) {
        if (interval == 0) {
            return "HH:mm:ss";
        }

        long seconds = interval / 60;
        long minutes = (interval / 60) / 60;
        long hours = interval / 3600;
        return String.format("%02d:%02d:%02d", hours, minutes, seconds);
    }
}
