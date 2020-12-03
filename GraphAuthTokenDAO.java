package DAO.Graph;

import Context.HttpUtils;
import DAO.Graph.Model.AddTokenRequest;
import DAO.IAuthTokenDAO;
import com.google.gson.Gson;

import java.net.HttpURLConnection;
import java.net.URL;
import java.util.UUID;

public class GraphAuthTokenDAO implements IAuthTokenDAO {
    public String addToken(String alias) {
        Gson g = new Gson();
        AddTokenRequest req = new AddTokenRequest();
        req.authToken = UUID.randomUUID().toString();
        req.alias = alias;

        try {
            URL url = new URL("http://localhost:8080/sky/event/" + Graph.eci + "/java/jacebook/add_token");
            HttpURLConnection conn = (HttpURLConnection)url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setRequestProperty("Accept", "application/json");
            conn.setDoOutput(true);
            HttpUtils.writeString(g.toJson(req), conn.getOutputStream());
            conn.getOutputStream().close();
            conn.connect();
            System.out.println(HttpUtils.readString(conn.getInputStream()));
        } catch (Exception e) {
            e.printStackTrace();
        }


        return req.authToken;
    }

    public void removeToken(String authToken) {

    }

    public String authenticateToken(String authToken) {
        return "";
    }

    public static void main(String[] args) {
        GraphAuthTokenDAO token = new GraphAuthTokenDAO();
        token.addToken("b");

    }
}
