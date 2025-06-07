import com.mongodb.client.MongoClient;
import com.vaadin.demo.AIConfig;
import com.vaadin.demo.config.AIDocsProperties;
import com.vaadin.demo.config.MongoDbProperties;
import dev.langchain4j.memory.chat.ChatMemory;
import dev.langchain4j.memory.chat.ChatMemoryProvider;
import dev.langchain4j.model.chat.StreamingChatLanguageModel;
import dev.langchain4j.model.embedding.EmbeddingModel;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import org.mockito.Mockito;

class AIConfigTest {
    @Test
    void beansCreated() {
        AIDocsProperties props = new AIDocsProperties();
        AIDocsProperties.LangChain4j lc = new AIDocsProperties.LangChain4j();
        AIDocsProperties.LangChain4j.OpenAI open = new AIDocsProperties.LangChain4j.OpenAI();
        open.setBaseUrl("http://host");
        open.setModelName("model");
        open.setEmbeddingModelName("embed");
        lc.setOpenAi(open);
        props.setLangchain4j(lc);

        MongoDbProperties mongo = new MongoDbProperties();
        mongo.setUri("mongodb://localhost");
        mongo.setDatabase("db");
        mongo.setCollection("coll");

        AIConfig config = new AIConfig(props, mongo);
        MongoClient client = config.mongoClient();
        assertNotNull(client);
        EmbeddingModel embeddingModel = config.embeddingModel();
        assertNotNull(embeddingModel);
        ChatMemoryProvider provider = config.chatMemoryProvider();
        ChatMemory memory = provider.get("id");
        assertNotNull(memory);
        StreamingChatLanguageModel model = config.streamingChatLanguageModel();
        assertNotNull(model);
    }
}
