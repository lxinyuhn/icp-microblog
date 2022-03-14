import Iter "mo:base/Iter";
import List "mo:base/List";
import Time "mo:base/Time";
import Principal "mo:base/Principal";

actor Self{
    public type Message = {
        text: Text;
        time: Time.Time;
        author: Text;
    };
    public type Microblog = actor {
        follow: shared(Principal) -> async ();
        follows: shared query () -> async [Principal];
        post: shared (Text) -> async ();
        posts: shared query (Time.Time) -> async [Message];
        timeline: shared (Time.Time) -> async [Message];
    };

    stable var name: Text = "";

    public shared func set_name(new_name: Text): async() { 
        name := new_name
    };

    public shared query func get_name(): async ?Text {
        ?name
    };

    stable var followed: List.List<Text> = List.nil();

    public shared func follow(id: Principal): async(){
        followed := List.push(Principal.toText(id), followed)
    };

    public shared query func follows(): async [Text]{
        List.toArray(followed)
    };

    stable var messages: List.List<Message> = List.nil();

    public shared(context) func post(secret: Text, text: Text): async (){
        assert(secret == "54321");
        let myself : Principal = Principal.fromActor(Self);
        // assert(Principal.toText(msg.caller) == "bwoy3-pze24-rjms4-vz2vo-etg4j-notgb-b3kmk-zog7c-7qb5f-6zbqn-mqe");
        let message: Message = {
            text = text;
            time = Time.now();
            author = Principal.toText(myself);
        };
        messages := List.push(message, messages);
    };
    
    public shared query func posts(since: Time.Time): async [Message]{
        List.toArray(List.filter<Message>(messages, func (msg){msg.time > since}))
    };

    public shared func timeline(since: Time.Time): async [Message]{
        var all: List.List<Message> = List.nil();
        for ( id in Iter.fromList(followed)){
            let canister: Microblog = actor(id);
            let msgs = await canister.posts(since);
            for (msg in Iter.fromArray(msgs)){
                all := List.push(msg, all);
            }
        };
        for (msg in Iter.fromArray(List.toArray(messages))){
            all := List.push(msg, all);
        };
        List.toArray(all)
    };
};
