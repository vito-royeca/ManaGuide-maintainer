package com.managuide.maintainer;

import java.net.URL;
import java.nio.charset.Charset;
import java.util.Date;

import com.manakit.ManaKit;
import org.apache.commons.io.IOUtils;
import org.jdeferred2.Deferred;
import org.jdeferred2.Promise;
import org.jdeferred2.impl.DeferredObject;
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
        startActivity();

        //Deferred deferred = new DeferredObject();
        //Promise promise = deferred.promise();
        SetsMaintainer sm = new SetsMaintainer();
        sm.fetchSetsData();

        endActivity();
    }

    /**
     * Utility methods
     */
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
