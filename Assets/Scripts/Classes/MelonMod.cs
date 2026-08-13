using Thor.Core;
using UnityEngine;

namespace Mod_35b6f284f4f14a74831dde938ee66cbd
{
    public class MelonMod : MonoBehaviour
    {
        [SerializeField]
        public PortalData Melon_Portal;

        private void Awake()
        {
            Services.Events.RegisterGameEvent(GameEventType.EncounterBegin, ev =>
            {
                if (ev.DataValue.GUID != "a2ee78b30ba04036a4f9ed0a2f79bb34")
                    return;

                Services.Entities.Spawn(new IEntityService.SpawnParams
                {
                    data = Melon_Portal,
                    position = new Vector3(5.6f, 0, 4f),
                    scale = new Vector3(1, 1, 1),
                    rotation = Quaternion.identity
                }, out _);
            });
        }
    }

}
