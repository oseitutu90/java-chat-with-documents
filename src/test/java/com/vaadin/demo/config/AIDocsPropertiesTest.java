import com.vaadin.demo.config.AIDocsProperties;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class AIDocsPropertiesTest {
    @Test
    void gettersAndSettersWork() {
        AIDocsProperties props = new AIDocsProperties();
        props.setLocation("loc");
        AIDocsProperties.LangChain4j lc = new AIDocsProperties.LangChain4j();
        AIDocsProperties.LangChain4j.OpenAI open = new AIDocsProperties.LangChain4j.OpenAI();
        open.setApiKey("key");
        open.setBaseUrl("url");
        open.setModelName("model");
        open.setEmbeddingModelName("embed");
        open.setBaseUrlChat("chatUrl");
        lc.setOpenAi(open);
        props.setLangchain4j(lc);

        assertEquals("loc", props.getLocation());
        assertEquals(lc, props.getLangchain4j());
        assertEquals(open, props.getLangchain4j().getOpenAi());
        assertEquals("key", open.getApiKey());
        assertEquals("url", open.getBaseUrl());
        assertEquals("model", open.getModelName());
        assertEquals("embed", open.getEmbeddingModelName());
        assertEquals("chatUrl", open.getBaseUrlChat());
    }
}
