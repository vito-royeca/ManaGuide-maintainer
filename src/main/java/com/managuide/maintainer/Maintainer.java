package com.managuide.maintainer;

import java.net.URL;
import java.nio.charset.Charset;

import com.manakit.ManaKit;
import org.apache.commons.io.IOUtils;
import org.json.JSONArray;
import org.json.JSONObject;

import com.manakit.ManaKit;

public class Maintainer {
    public void checkServerInfo() {
        try {
            String sURL = "http://192.168.1.182:1993/serverinfo?json=true";

            JSONArray array = new JSONArray(IOUtils.toString(new URL(sURL), Charset.forName("UTF-8")));
            Boolean willUpdate = false;

            for (Object object : array) {
                JSONObject json = (JSONObject) object;
                String scryfallVersion = json.getString("scryfall_version");
                willUpdate = scryfallVersion != ManaKit.Constants.ServerInfo.getValue();
            }

            if (willUpdate) {
                updateDatabase();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    void updateDatabase() {
        System.out.println("We will update the database");
    }
}
