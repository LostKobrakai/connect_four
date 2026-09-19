import {
  createSignal,
  createEffect,
  For,
  Show,
  action,
  affects,
  isPending,
  until,
} from "solid-js";
import { render } from "@solidjs/web";
import html from "@solidjs/html";

function discColorClass(playerIndex) {
  return { 0: "bg-amber-400", 1: "bg-red-500" }[playerIndex] ?? "bg-zinc-700";
}

function socketUrl(server, name) {
  const trimmed = server.trim();
  const url = new URL(trimmed.includes("://") ? trimmed : `ws://${trimmed}`);
  url.protocol = "ws:";
  url.pathname = `${url.pathname.replace(/\/+$/, "")}/ws`;
  url.searchParams.set("name", name);
  return url.toString();
}

function playerName(game, index) {
  return game.players[index] ?? `Player ${index}`;
}

function StartScreen(props) {
  const [server, setServer] = createSignal(window.location.host);
  const [name, setName] = createSignal("");

  const submit = (e) => {
    e.preventDefault();
    if (!server().trim() || !name().trim()) return;
    props.onConnect(server(), name());
  };

  return html`
    <div class="w-80 p-8 bg-zinc-800 rounded-xl">
      <h1 class="mb-6 text-2xl text-center">Connect Four</h1>
      <form class="flex flex-col gap-4" onSubmit=${submit}>
        <label class="flex flex-col gap-[0.35rem] text-[0.85rem] text-zinc-500">
          <span>
            Server
            <abbr class="text-red-500" title="Required">*</abbr>
          </span>
          <input
            class="bg-zinc-900 border border-zinc-700 rounded-[0.4rem] py-2 px-[0.6rem] font-[inherit] text-[inherit] text-zinc-100 placeholder:text-zinc-500"
            type="text"
            value=${server}
            onInput=${(e) => setServer(e.target.value)}
            placeholder="localhost:4000"
            required
          />
        </label>
        <label class="flex flex-col gap-[0.35rem] text-[0.85rem] text-zinc-500">
          <span>
            Name
            <abbr class="text-red-500" title="Required">*</abbr>
          </span>
          <input
            class="bg-zinc-900 border border-zinc-700 rounded-[0.4rem] py-2 px-[0.6rem] font-[inherit] text-[inherit] text-zinc-100 placeholder:text-zinc-500"
            type="text"
            value=${name}
            onInput=${(e) => setName(e.target.value)}
            placeholder="your name"
            required
          />
        </label>
        <button
          class="cursor-pointer mt-2 p-[0.6rem] bg-blue-400 border-none rounded-[0.4rem] font-semibold disabled:opacity-60 disabled:cursor-default"
          type="submit"
          disabled=${() => props.connecting}
        >
          ${() => (props.connecting ? "Connecting…" : "Connect")}
        </button>
      </form>
      <${Show} when=${() => props.error}>
        <p class="text-red-500 text-[0.85rem]">${() => props.error}</p>
      <//>
    </div>
  `;
}

function StatusBar(props) {
  function text() {
    const state = props.game.state;

    if (state === "setup") return "Waiting for opponent…";
    if (state === "draw") return "Draw!";

    const [kind, index] = state;

    if (kind === "won") return `${playerName(props.game, index)} won!`;
    if (kind === "turn") {
      return props.playersTurn
        ? "Your turn"
        : `${playerName(props.game, index)}'s turn`;
    }
  }

  return html`<p
    class="mb-4 flex items-center justify-center gap-2 font-semibold"
  >
    ${text}
    <${Show} when=${() => isPending(() => props.game)}>
      <span class="w-2 h-2 rounded-full bg-blue-400 animate-pulse"></span>
    <//>
  </p>`;
}

function Legend(props) {
  return html`
    <ul
      class="list-none mt-4 mb-0 p-0 flex flex-col gap-[0.4rem] text-[0.9rem]"
    >
      <${For} each=${() => props.game.players}>
        ${(name, index) => html`
          <li
            class=${name ? "flex items-center gap-2" : "flex items-center gap-2 text-zinc-500 italic"}
          >
            <span
              class=${() => `w-[0.8rem] h-[0.8rem] rounded-full flex-none ${discColorClass(name ? index() : null)}`}
            ></span>
            ${name ?? "waiting for player"}
          </li>
        `}
      <//>
    </ul>
  `;
}

function Board(props) {
  const columns = () => props.board.columns;
  const rows = () => props.board.rows;
  const rowIndexes = () =>
    Array.from({ length: rows() }, (_, i) => rows() - 1 - i);
  const colIndexes = () => Array.from({ length: columns() }, (_, i) => i);
  const gridStyle = () => ({
    "grid-template-columns": `repeat(${columns()}, 1fr)`,
  });
  const cellState = (x, y) => props.board.state[y * columns() + x] ?? null;

  return html`
    <div class="grid gap-[0.4rem] mb-[0.4rem]" style=${gridStyle}>
      <${For} each=${colIndexes}>
        ${(x) => html`
          <button
            class="aspect-square bg-zinc-700 border-none rounded-[0.3rem] text-zinc-200 disabled:opacity-[0.35] disabled:cursor-default"
            disabled=${() => !props.playersTurn || isPending(() => props.board)}
            onClick=${() => props.onDrop(x)}
          >
            ▼
          </button>
        `}
      <//>
    </div>
    <div
      class="grid gap-[0.4rem] p-[0.6rem] bg-zinc-900 rounded-lg"
      style=${gridStyle}
    >
      <${For} each=${rowIndexes}>
        ${(y) => html`
          <${For} each=${colIndexes}>
            ${(x) => html`
              <div
                class=${() => `aspect-square rounded-full ${discColorClass(cellState(x, y))}`}
              ></div>
            `}
          <//>
        `}
      <//>
    </div>
  `;
}

function GameView(props) {
  return html`
    <div class="w-[26rem] p-6 bg-zinc-800 rounded-xl">
      <${StatusBar}
        game=${() => props.game}
        playersTurn=${() => props.playersTurn}
      />
      <${Show} when=${() => props.error}>
        <p class="text-red-500 text-[0.85rem]">${() => props.error}</p>
      <//>
      <${Board}
        board=${() => props.game.board}
        playersTurn=${() => props.playersTurn}
        onDrop=${props.onDrop}
      />
      <${Legend} game=${() => props.game} />
    </div>
  `;
}

function createConnection(credentials) {
  const [game, setGame] = createSignal(null);
  const [playersTurn, setPlayersTurn] = createSignal(false);
  const [error, setError] = createSignal(null);
  const [socket, setSocket] = createSignal(null);
  // Bumped on every message, so an in-flight action can tell
  // "the server answered" apart from "nothing happened yet".
  const [messageCount, setMessageCount] = createSignal(0);

  createEffect(
    () => credentials(),
    (creds) => {
      if (!creds) return;

      setError(null);
      setGame(null);

      const ws = new WebSocket(socketUrl(creds.server, creds.name));

      ws.onopen = () => setSocket(ws);

      ws.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        setMessageCount((count) => count + 1);

        if (msg.type === "error") {
          setError(msg.reason);
          return;
        }

        setError(null);
        setGame(msg.game_state);
        setPlayersTurn(msg.players_turn);
      };

      ws.onclose = () => {
        const wasOpen = socket() === ws;
        setSocket(null);
        setGame(null);
        if (wasOpen) setError("Connection closed");
      };

      ws.onerror = () => setError("Could not connect");

      return () => ws.close();
    },
  );

  return {
    game,
    playersTurn,
    error,
    setError,
    socket,
    messageCount,
  };
}

function App() {
  const [credentials, setCredentials] = createSignal(null);
  const { game, playersTurn, error, setError, socket, messageCount } =
    createConnection(credentials);
  const sendDrop = action(function* (index) {
    affects(game);
    const before = messageCount();
    socket()?.send(JSON.stringify({ type: "drop", index }));
    yield until(() => messageCount() > before, {
      timeout: 5000,
    });
  });

  function dropDisc(index) {
    if (isPending(game)) return;
    sendDrop(index).catch((err) =>
      setError(err instanceof Error ? err.message : String(err)),
    );
  }

  return html`
    <${Show}
      when=${() => game()}
      fallback=${html`<${StartScreen}
        onConnect=${(server, name) => setCredentials({ server, name })}
        connecting=${() => !!credentials() && !socket() && !error()}
        error=${error}
      />`}
    >
      <${GameView}
        game=${game}
        playersTurn=${playersTurn}
        error=${error}
        onDrop=${dropDisc}
      />
    <//>
  `;
}

render(App, document.getElementById("app"));
